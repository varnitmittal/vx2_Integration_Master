import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import fireMockCallout from '@salesforce/apex/StripeMockDataController.fireMockCallout';

export default class StripeMockData extends LightningElement {
  @api recordId;

  statusCode = 503;
  response = null;
  errorMessage = null;
  isLoading = false;

  handleStatusCodeChange(event) {
    this.statusCode = event.target.value;
    this.errorMessage = null;
  }

  handleSend() {
    const input = this.template.querySelector('lightning-input');

    if (!input.reportValidity()) {
      return;
    }

    this.isLoading = true;
    this.errorMessage = null;
    this.response = null;

    fireMockCallout({
      recordId: this.recordId,
      statusCode: Number(this.statusCode)
    })
      .then(result => {
        this.response = result;
      })
      .catch(error => {
        this.errorMessage =
          error?.body?.message ||
          error?.message ||
          'Callout failed.';
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  get responseBody() {
    if (!this.response?.body) {
      return '';
    }

    try {
      return JSON.stringify(
        JSON.parse(this.response.body),
        null,
        2
      );
    } catch (e) {
      return this.response.body;
    }
  }

  get responseHeaders() {
    if (!this.response?.headers) {
      return [];
    }

    return Object.entries(this.response.headers).map(([key, value]) => ({
      key,
      value
    }));
  }

  get hasResponse() {
    return this.response !== null;
  }

  handleInputKeyDown(event) {
    if (event.key === 'Enter') {
      event.preventDefault();
      this.handleSend();
    }
  }
}