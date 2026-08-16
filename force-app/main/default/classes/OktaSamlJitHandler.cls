global class OktaSamlJitHandler implements Auth.SamlJitHandler {
  
  global User createUser(
    Id samlSsoProviderId,
  Id communityId,
  Id portalId,
  String federationIdentifier,
  Map<String, String> attributes,
  String assertion
  ) {
    System.debug('Federation ID: ' + federationIdentifier);
    System.debug('SAML Attributes: ' + attributes);
    
    User u = new User();
    
    // NameID from Okta
    u.FederationIdentifier = federationIdentifier;
    
    // For your current setup, NameID is the user's email.
    u.Email = federationIdentifier;
    u.Username = federationIdentifier;
    
    // Temporary/default values for testing
    u.FirstName = 'Okta';
    u.LastName = 'User';
    u.Alias = 'oktauser';
    
    u.TimeZoneSidKey = 'America/Los_Angeles';
    u.LocaleSidKey = 'en_US';
    u.LanguageLocaleKey = 'en_US';
    u.EmailEncodingKey = 'UTF-8';
    
    u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
    
    return u;
  }
  
  global void updateUser(
    Id userId,
  Id samlSsoProviderId,
  Id communityId,
  Id portalId,
  String federationIdentifier,
  Map<String, String> attributes,
  String assertion
  ) {
    System.debug('Federation ID: ' + federationIdentifier);
    System.debug('SAML Attributes: ' + attributes);
    
    User u = [SELECT Id, FirstName, LastName, Email, FederationIdentifier FROM User WHERE Id = :userId LIMIT 1];
    
    u.FederationIdentifier = federationIdentifier;
    u.Email = federationIdentifier;
    
    update u;
  }
}