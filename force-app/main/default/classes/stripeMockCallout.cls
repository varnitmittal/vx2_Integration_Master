public with sharing class stripeMockCallout {
  private String mockStatusCode;
  
  public StripeMockCallout(String mockStatusCode) {
    this.mockStatusCode = mockStatusCode;
  }
  
  private HttpRequest calloutRequestImpl() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:stripeMockAPI/api/mock-stripe?code=' + mockStatusCode);
    req.setMethod('GET');
    return req;
  }
  
  public HttpResponse fireCallout() {
    return new Http().send(calloutRequestImpl());
  }
}