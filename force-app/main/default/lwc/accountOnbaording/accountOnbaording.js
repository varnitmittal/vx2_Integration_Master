import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import getRelatedRecords from '@salesforce/apex/AccountOnboardingUIController.getRelatedRecords';

export default class AccountOnboarding extends LightningElement {
  selectedAccountId;
  accountRecordTypeId;

  showConfirmation = false;
  onboardingConfirmed = false;

  contacts = [];
  leads = [];

  isLoadingRelatedRecords = false;
  alreadyOnboarded = false;

  onboardingStorageKey = 'accountOnboardingIds';
  onboardingStorageDuration = 10 * 60 * 1000;

  onboardingStatusInterval;


  connectedCallback() {
    this.startOnboardingStatusCheck();
  }


  disconnectedCallback() {
    this.stopOnboardingStatusCheck();
  }


  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  handleAccountObjectInfo({ data, error }) {
    if (data) {
      const recordTypeInfos = data.recordTypeInfos;

      const prospectiveRecordType = Object.values(recordTypeInfos)
        .find(recordType =>
          recordType.name === 'Prospective' &&
          recordType.available
        );

      if (prospectiveRecordType) {
        this.accountRecordTypeId =
          prospectiveRecordType.recordTypeId;
      } else {
        console.error(
          'Prospective Account record type not found.'
        );
      }
    } else if (error) {
      console.error(
        'Error loading Account metadata:',
        error
      );
    }
  }


  get accountFilter() {
    if (!this.accountRecordTypeId) {
      return undefined;
    }

    return {
      criteria: [
        {
          fieldPath: 'RecordTypeId',
          operator: 'eq',
          value: this.accountRecordTypeId
        }
      ]
    };
  }


  handleAccountChange(event) {
    this.selectedAccountId = event.detail.recordId;

    this.alreadyOnboarded = false;
    this.onboardingConfirmed = false;
    this.showConfirmation = false;

    if (!this.selectedAccountId) {
      return;
    }

    this.checkOnboardingStatus();

    console.log(
      'Selected Account:',
      this.selectedAccountId
    );
  }


  handleOnboard() {
    if (!this.selectedAccountId) {
      return;
    }

    const now = Date.now();

    const storedData = JSON.parse(
      localStorage.getItem(this.onboardingStorageKey) || '{}'
    );

    const accountData = storedData[this.selectedAccountId];

    if (accountData) {
      const onboardingTime = accountData.timestamp;

      if (
        onboardingTime &&
        now - onboardingTime < this.onboardingStorageDuration
      ) {
        this.alreadyOnboarded = true;

        console.log(
          'Account is already being onboarded:',
          this.selectedAccountId
        );

        return;
      }

      // Remove expired entry.
      delete storedData[this.selectedAccountId];

      localStorage.setItem(
        this.onboardingStorageKey,
        JSON.stringify(storedData)
      );
    }

    this.alreadyOnboarded = false;
    this.isLoadingRelatedRecords = true;

    getRelatedRecords({
      accountId: this.selectedAccountId
    })
      .then(result => {
        this.contacts = (result.contacts || []).map(contact => ({
          ...contact,
          recordUrl:
            `/lightning/r/Contact/${contact.Id}/view`
        }));

        this.leads = (result.leads || []).map(lead => ({
          ...lead,
          recordUrl:
            `/lightning/r/Lead/${lead.Id}/view`
        }));

        this.onboardingConfirmed = false;
        this.showConfirmation = true;
      })
      .catch(error => {
        console.error(
          'Error loading related records:',
          error
        );

        this.contacts = [];
        this.leads = [];
      })
      .finally(() => {
        this.isLoadingRelatedRecords = false;
      });
  }


  handleCancel() {
    this.showConfirmation = false;
    this.onboardingConfirmed = false;
  }


  handleConfirm() {
    if (!this.selectedAccountId) {
      return;
    }

    const storedData = JSON.parse(
      localStorage.getItem(this.onboardingStorageKey) || '{}'
    );

    storedData[this.selectedAccountId] = {
      status: 'IN_PROGRESS',
      timestamp: Date.now()
    };

    localStorage.setItem(
      this.onboardingStorageKey,
      JSON.stringify(storedData)
    );

    this.onboardingConfirmed = true;

    console.log(
      'Account onboarding started:',
      this.selectedAccountId
    );

    // TODO:
    // Call Apex here to actually start onboarding.
  }


  startOnboardingStatusCheck() {
    this.checkOnboardingStatus();

    this.onboardingStatusInterval = setInterval(() => {
      this.checkOnboardingStatus();
    }, 60 * 1000);
  }


  stopOnboardingStatusCheck() {
    if (this.onboardingStatusInterval) {
      clearInterval(this.onboardingStatusInterval);
      this.onboardingStatusInterval = null;
    }
  }


  checkOnboardingStatus() {
    if (!this.selectedAccountId) {
      return;
    }

    const storedData = JSON.parse(
      localStorage.getItem(this.onboardingStorageKey) || '{}'
    );

    const accountData = storedData[this.selectedAccountId];

    if (!accountData) {
      this.alreadyOnboarded = false;
      return;
    }

    const now = Date.now();
    const onboardingTime = accountData.timestamp;


    // Remove entries older than 10 minutes.
    if (
      onboardingTime &&
      now - onboardingTime >= this.onboardingStorageDuration
    ) {
      delete storedData[this.selectedAccountId];

      localStorage.setItem(
        this.onboardingStorageKey,
        JSON.stringify(storedData)
      );

      this.alreadyOnboarded = false;
      this.onboardingConfirmed = false;

      return;
    }


    // ============================
    // IN PROGRESS
    // ============================

    if (accountData.status === 'IN_PROGRESS') {
      this.alreadyOnboarded = true;

      // If the modal is already open, keep showing
      // the onboarding-in-progress screen.
      if (this.showConfirmation) {
        this.onboardingConfirmed = true;
      }

      return;
    }


    // ============================
    // COMPLETED
    // ============================

    if (accountData.status === 'COMPLETED') {

      this.alreadyOnboarded = false;

      // Show notification.
      this.showOnboardingCompleteNotification();

      // Close the modal.
      this.onboardingConfirmed = false;
      this.showConfirmation = false;

      // Remove completed account from storage.
      delete storedData[this.selectedAccountId];

      localStorage.setItem(
        this.onboardingStorageKey,
        JSON.stringify(storedData)
      );

      console.log(
        'Account onboarding completed:',
        this.selectedAccountId
      );

      return;
    }


    console.log(
      'Onboarding status:',
      this.selectedAccountId,
      accountData.status
    );
  }

  showOnboardingCompleteNotification() {
    const event = new ShowToastEvent({
      title: 'Account Onboarding Complete',
      message: 'The account has been successfully onboarded.',
      variant: 'success',
      mode: 'sticky'
    });

    this.dispatchEvent(event);
  }
}