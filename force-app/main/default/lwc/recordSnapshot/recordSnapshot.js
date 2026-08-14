import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import RecordSnapshotProcessor from '@salesforce/apex/RecordSnapshotController.RecordSnapshotProcessor';

export default class RecordSnapshot extends LightningElement {
  @api recordId;
  @api objectApiName;

  errorMessage = null;
  isLoading = false;

  renderedCallback() {
    console.log('recordId:', this.recordId, 'type:', typeof this.recordId);
    console.log('objectApiName:', this.objectApiName, 'type:', typeof this.objectApiName);
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async handleConfirm() {
    this.errorMessage = null;
    this.isLoading = true;
    try {
      await RecordSnapshotProcessor({
        input: {
          recordId: this.recordId,
          objectApiName: this.objectApiName
        }
      });

      // Close modal after successful processing
      this.dispatchEvent(new CloseActionScreenEvent());

    } catch (error) {
      this.errorLoggingToConsole(error);
      this.errorMessage =
        error?.body?.message ||
        'An unexpected error occurred while processing the snapshot.';
    } finally {
      this.isLoading = false;
    }
  }

  errorLoggingToConsole(err) {
    console.error('ERROR:', JSON.stringify(err));
    console.error('Body:', JSON.stringify(err.body));
    console.error('Message:', err.body?.message)
  }
}