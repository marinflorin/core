@api @federation-app-required @TestAlsoOnExternalUserBackend
Feature: federated

  Background:
    Given using OCS API version "1"
    And using server "REMOTE"
    And user "user0" has been created with default attributes
    And using server "LOCAL"
    And user "user1" has been created with default attributes

  Scenario: Federate share a file with another server
    When user "user1" from server "LOCAL" shares "/textfile0.txt" with user "user0" from server "REMOTE" using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And the share fields of the last share should include
      | id                     | A_NUMBER       |
      | item_type              | file           |
      | item_source            | A_NUMBER       |
      | share_type             | 6              |
      | file_source            | A_NUMBER       |
      | path                   | /textfile0.txt |
      | permissions            | 19             |
      | stime                  | A_NUMBER       |
      | storage                | A_NUMBER       |
      | mail_send              | 0              |
      | uid_owner              | user1          |
      | file_parent            | A_NUMBER       |
      | displayname_owner      | User One       |
      | share_with             | user0@REMOTE   |
      | share_with_displayname | user0@REMOTE   |

  Scenario: Federate share a file with local server
    When user "user0" from server "REMOTE" shares "/textfile0.txt" with user "user1" from server "LOCAL" using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And the share fields of the last share should include
      | id                     | A_NUMBER       |
      | item_type              | file           |
      | item_source            | A_NUMBER       |
      | share_type             | 6              |
      | file_source            | A_NUMBER       |
      | path                   | /textfile0.txt |
      | permissions            | 19             |
      | stime                  | A_NUMBER       |
      | storage                | A_NUMBER       |
      | mail_send              | 0              |
      | uid_owner              | user0          |
      | file_parent            | A_NUMBER       |
      | displayname_owner      | User Zero      |
      | share_with             | user1@LOCAL    |
      | share_with_displayname | user1@LOCAL    |

  Scenario: Remote sharee can see the pending share
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    When user "user1" gets the list of pending federated cloud shares using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | id          | A_NUMBER                                   |
      | remote      | REMOTE                                     |
      | remote_id   | A_NUMBER                                   |
      | share_token | A_TOKEN                                    |
      | name        | /textfile0.txt                             |
      | owner       | user0                                      |
      | user        | user1                                      |
      | mountpoint  | {{TemporaryMountPointName#/textfile0.txt}} |
      | accepted    | 0                                          |

  Scenario: Remote sharee requests information of only one share
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    When user "user1" retrieves the information of the last federated cloud share using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | id          | A_NUMBER           |
      | remote      | REMOTE             |
      | remote_id   | A_NUMBER           |
      | share_token | A_TOKEN            |
      | name        | /textfile0.txt     |
      | owner       | user0              |
      | user        | user1              |
      | mountpoint  | /textfile0 (2).txt |
      | accepted    | 1                  |
      | type        | file               |
      | permissions | 27                 |

  @issue-34636
  Scenario: Remote sharee requests information of only one share before accepting it
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    When user "user1" retrieves the information of the last pending federated cloud share using the sharing API
    Then the HTTP status code should be "200" or "500"
    And the body of the response should be empty
    #Then the HTTP status code should be "200"
    #And the OCS status code should be "100"
    #And the fields of the last response should include
    #  | id          | A_NUMBER                                   |
    #  | remote      | REMOTE                                     |
    #  | remote_id   | A_NUMBER                                   |
    #  | share_token | A_TOKEN                                    |
    #  | name        | /textfile0.txt                             |
    #  | owner       | user0                                      |
    #  | user        | user1                                      |
    #  | mountpoint  | {{TemporaryMountPointName#/textfile0.txt}} |
    #  | accepted    | 0                                          |

  Scenario: sending a GET request to a pending remote share is not valid
    When user "user1" sends HTTP method "GET" to OCS API endpoint "/apps/files_sharing/api/v1/remote_shares/pending/12"
    Then the HTTP status code should be "405"
    And the body of the response should be empty

  Scenario: sending a GET request to a not existing remote share
    When user "user1" sends HTTP method "GET" to OCS API endpoint "/apps/files_sharing/api/v1/remote_shares/9999999999"
    Then the OCS status code should be "404"
    And the HTTP status code should be "200"

  Scenario: accept a pending remote share
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    When user "user1" from server "LOCAL" accepts the last pending share using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"

  Scenario: Reshare a federated shared file
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    And using server "LOCAL"
    And user "user2" has been created with default attributes
    When user "user1" creates a share using the sharing API with settings
      | path        | /textfile0 (2).txt |
      | shareType   | 0                  |
      | shareWith   | user2              |
      | permissions | 19                 |
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And the share fields of the last share should include
      | id                     | A_NUMBER           |
      | item_type              | file               |
      | item_source            | A_NUMBER           |
      | share_type             | 0                  |
      | file_source            | A_NUMBER           |
      | path                   | /textfile0 (2).txt |
      | permissions            | 19                 |
      | stime                  | A_NUMBER           |
      | storage                | A_NUMBER           |
      | mail_send              | 0                  |
      | uid_owner              | user1              |
      | file_parent            | A_NUMBER           |
      | displayname_owner      | User One           |
      | share_with             | user2              |
      | share_with_displayname | User Two           |

  Scenario: Overwrite a federated shared file as recipient - local server shares - remote server receives
    Given user "user1" from server "LOCAL" has shared "/textfile0.txt" with user "user0" from server "REMOTE"
    And user "user0" from server "REMOTE" has accepted the last pending share
    And using server "REMOTE"
    When user "user0" uploads file "filesForUpload/file_to_overwrite.txt" to "/textfile0 (2).txt" using the WebDAV API
    Then the HTTP status code should be "204"
    And the content of file "/textfile0.txt" for user "user1" on server "LOCAL" should be "BLABLABLA" plus end-of-line

  Scenario: Overwrite a federated shared file as recipient - remote server shares - local server receives
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    When user "user1" uploads file "filesForUpload/file_to_overwrite.txt" to "/textfile0 (2).txt" using the WebDAV API
    Then the HTTP status code should be "204"
    And the content of file "/textfile0.txt" for user "user0" on server "REMOTE" should be "BLABLABLA" plus end-of-line

  Scenario: Overwrite a file in a federated shared folder as recipient - local server shares - remote server receives
    Given user "user1" from server "LOCAL" has shared "/PARENT" with user "user0" from server "REMOTE"
    And user "user0" from server "REMOTE" has accepted the last pending share
    And using server "REMOTE"
    When user "user0" uploads file "filesForUpload/file_to_overwrite.txt" to "/PARENT (2)/textfile0.txt" using the WebDAV API
    Then the HTTP status code should be "201"
    And the content of file "/PARENT/textfile0.txt" for user "user1" on server "LOCAL" should be "BLABLABLA" plus end-of-line

  Scenario: Overwrite a file in a federated shared folder as recipient - remote server shares - local server receives
    Given user "user0" from server "REMOTE" has shared "/PARENT" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    When user "user1" uploads file "filesForUpload/file_to_overwrite.txt" to "/PARENT (2)/textfile0.txt" using the WebDAV API
    Then the HTTP status code should be "201"
    And the content of file "/PARENT/textfile0.txt" for user "user0" on server "REMOTE" should be "BLABLABLA" plus end-of-line

  Scenario: Overwrite a federated shared file as recipient using old chunking
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    When user "user1" uploads the following "3" chunks to "/textfile0 (2).txt" with old chunking and using the WebDAV API
      | 1 | AAAAA |
      | 2 | BBBBB |
      | 3 | CCCCC |
    Then the HTTP status code should be "201"
    And the content of file "/textfile0 (2).txt" for user "user1" should be "AAAAABBBBBCCCCC"
    And the content of file "/textfile0.txt" for user "user0" on server "REMOTE" should be "AAAAABBBBBCCCCC"

  Scenario: Overwrite a file in a federated shared folder as recipient using old chunking
    Given user "user0" from server "REMOTE" has shared "/PARENT" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    When user "user1" uploads the following "3" chunks to "/PARENT (2)/textfile0.txt" with old chunking and using the WebDAV API
      | 1 | AAAAA |
      | 2 | BBBBB |
      | 3 | CCCCC |
    Then the HTTP status code should be "201"
    And the content of file "/PARENT (2)/textfile0.txt" for user "user1" should be "AAAAABBBBBCCCCC"
    And the content of file "/PARENT/textfile0.txt" for user "user0" on server "REMOTE" should be "AAAAABBBBBCCCCC"

  Scenario: Remote sharee deletes an accepted federated share
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    When user "user1" deletes the last federated cloud share using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And user "user1" should not see the following elements
      | /textfile0%20(2).txt      |
    When user "user1" gets the list of federated cloud shares using the sharing API
    Then the response should contain 0 entries
    When user "user1" gets the list of pending federated cloud shares using the sharing API
    Then the response should contain 0 entries

  Scenario: Remote sharee tries to delete an accepted federated share sending wrong password
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    When user "user1" deletes the last federated cloud share with password "invalid" using the sharing API
    Then the OCS status code should be "997"
    And the HTTP status code should be "401"
    And user "user1" should see the following elements
      | /textfile0%20(2).txt      |
    When user "user1" gets the list of federated cloud shares using the sharing API
    Then the fields of the last response should include
      | id          | A_NUMBER           |
      | remote      | REMOTE             |
      | remote_id   | A_NUMBER           |
      | share_token | A_TOKEN            |
      | name        | /textfile0.txt     |
      | owner       | user0              |
      | user        | user1              |
      | mountpoint  | /textfile0 (2).txt |
      | accepted    | 1                  |
      | type        | file               |
      | permissions | 27                 |
    When user "user1" gets the list of pending federated cloud shares using the sharing API
    Then the response should contain 0 entries

  Scenario: Remote sharee deletes a pending federated share
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    When user "user1" deletes the last pending federated cloud share using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And user "user1" should not see the following elements
      | /textfile0%20(2).txt      |
    When user "user1" gets the list of federated cloud shares using the sharing API
    Then the response should contain 0 entries
    When user "user1" gets the list of pending federated cloud shares using the sharing API
    Then the response should contain 0 entries

  Scenario: Remote sharee tries to delete a pending federated share sending wrong password
    Given user "user0" from server "REMOTE" has shared "/textfile0.txt" with user "user1" from server "LOCAL"
    When user "user1" deletes the last pending federated cloud share with password "invalid" using the sharing API
    Then the OCS status code should be "997"
    And the HTTP status code should be "401"
    And user "user1" should not see the following elements
      | /textfile0%20(2).txt      |
    When user "user1" gets the list of pending federated cloud shares using the sharing API
    Then the fields of the last response should include
      | id          | A_NUMBER                                   |
      | remote      | REMOTE                                     |
      | remote_id   | A_NUMBER                                   |
      | share_token | A_TOKEN                                    |
      | name        | /textfile0.txt                             |
      | owner       | user0                                      |
      | user        | user1                                      |
      | mountpoint  | {{TemporaryMountPointName#/textfile0.txt}} |
      | accepted    | 0                                          |
    When user "user1" gets the list of federated cloud shares using the sharing API
    Then the response should contain 0 entries

  Scenario: Trusted server handshake does not require authenticated requests - we force 403 by sending an empty body
    Given using server "LOCAL"
    And using OCS API version "2"
    When user "UNAUTHORIZED_USER" requests shared secret using the federation API
    Then the HTTP status code should be "403"

  @skipOnLDAP
  Scenario: Upload file to received federated share while quota is set on home storage
    Given user "user0" from server "REMOTE" has shared "/PARENT" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    And using server "LOCAL"
    When user "user1" uploads file "filesForUpload/textfile.txt" to filenames based on "/PARENT (2)/testquota.txt" with all mechanisms using the WebDAV API
    Then the HTTP status code of all upload responses should be "201"
    And as user "user0" on server "REMOTE" the files uploaded to "/PARENT/testquota.txt" with all mechanisms should exist

  @skipOnLDAP
  Scenario: Upload file to received federated share while quota is set on remote storage - local server shares - remote server receives
    Given using server "LOCAL"
    And the quota of user "user1" has been set to "20 B"
    And user "user1" from server "LOCAL" has shared "/PARENT" with user "user0" from server "REMOTE"
    And user "user0" from server "REMOTE" has accepted the last pending share
    And using server "REMOTE"
    When user "user0" uploads file "filesForUpload/textfile.txt" to filenames based on "/PARENT (2)/testquota.txt" with all mechanisms using the WebDAV API
    Then the HTTP status code of all upload responses should be "507"

  @skipOnLDAP
  Scenario: Upload file to received federated share while quota is set on remote storage - remote server shares - local server receives
    Given using server "REMOTE"
    And the quota of user "user0" has been set to "20 B"
    And user "user0" from server "REMOTE" has shared "/PARENT" with user "user1" from server "LOCAL"
    And user "user1" from server "LOCAL" has accepted the last pending share
    And using server "LOCAL"
    When user "user1" uploads file "filesForUpload/textfile.txt" to filenames based on "/PARENT (2)/testquota.txt" with all mechanisms using the WebDAV API
    Then the HTTP status code of all upload responses should be "507"
