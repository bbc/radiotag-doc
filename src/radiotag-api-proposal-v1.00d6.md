% RadioTAG 1.00 specification, draft 6
% Sean O'Halpin (BBC R&D); Chris Lowis (BBC R&D)
% 2014-02-
## Front matter
### Authors

Sean O'Halpin (BBC R&D), Chris Lowis (BBC R&D)

### Contributors

Andy Buckingham (togglebit), Robin Cooksey (Frontier Silicon)

### Published

- Draft 1: 2011-09-01
- Draft 2: 2011-10-27
- Draft 3: 2012-02-08
    - Changed /register return code from 201 to 204
- Draft 4: 2012-06-13
    - Conversion to pandoc markdown format
- Draft 5: 2012-07-30
    - Consistent capitalization of headers
    - Moved Narrative section into Appendix
    - 'anonymous' changed to 'unidentified'
    - 'unpaired' changed to 'receiver (identity)'
    - 'paired' changed to 'user (identity)'
    - 'client' changed to 'receiver'
    - 'can_register' changed to 'identity'
- Draft 6: 2014-02-

### URL

Unpublished at time of writing

## Abstract

This document specifies version 1.00 of the RadioTAG protocol.

The RadioTAG protocol defines how a receiver (e.g. an IP-enabled radio)
discovers whether a broadcaster supports RadioTAG and if so how it then
communicates with a broadcaster-provided web service to record the time
and station being listened to.

The protocol defines how a receiver obtains authorization to store
data on the server and how it can become paired with a user account so
that data can be accessed via the web.

The protocol also defines the format and content of the requests and
responses that pass between the receiver and server.

## How to read this document

The document starts with an overview of the [concepts](#concepts)
underlying the RadioTAG protocol. These concepts are summarized in the
[glossary](#glossary).

To get an idea of how the RadioTAG protocol works in practice, read
the two [narratives](#narratives) in the Appendix. These step through the
two most common scenarios to show what is communicated between the
receiver (radio) and the tag service at the HTTP level. This section is
particularly useful for developers who want to understand how the
various bits of the API hang together.

For full details about each endpoint provided by the tag service, read
the [API](#api) section.

Finally, to see how the Atom format is used in tag responses, what each
element contains and what limits apply, see [data formats](#data-formats).

## Concepts

A receiver sends a tag request to a tag service, specifying a time and
station. The tag service responds by sending a tag entry containing
relevant metadata. The tag data may be stored on the server and may be
viewed on the receiver or on the web or be used for another application.

### Service discovery

[TODO] RadioDNS lookup.

### HTTPS

[TODO] All API calls must use HTTPS.

### Tag requests

A tag *request* specifies a time and station. The time is specified
using seconds since Jan 1 1970, i.e. the Unix epoch. The station is
specified using the RadioDNS broadcast parameters.

How that information is interpreted is up to the broadcaster.

### Tag responses

The content of the *response* to a tag request is up to the
broadcaster but must follow the [Atom Syndication
Format](http://tools.ietf.org/html/rfc4287) as [specified
below](#tag-data). A tag response could contain programme, now playing
metadata, an advertising message or the response to a call for action.

### Receivers, radios and devices

In this specification, the **receiver** is any device or software program
that implements the receiver side of the RadioTAG specification. While
this would most commonly be an IP-enabled radio, it could also be, say,
an application running on a mobile phone or in a web browser.

### The tag service

The **tag service** is the web service provided by the broadcaster to
respond to receiver requests. It must implement a number of endpoints
depending on the level of service it provides.

### Levels of identity

There are three levels of identity a tag service can provide:

- anonymous
- receiver
- user

*User* in this context refers to an authenticated user account.

The levels of identification are distinguished by whether or not tags
are retrievable on the device or on the web and by whether you need a
user account on the broadcaster's web service. The table below
summarizes the differences:

---------------------------------------------------------------------
Level of identity  Tag list on device  Tag list on web  Account needed
-----------------  ------------------  ---------------  --------------
Unidentified       No                  No               No

Receiver           Yes                 No               No

User               Yes                 Yes              Yes

---------------------------------------------------------------------

These levels of identification can be provided in a number of
combinations. For example, a service may offer anonymous tagging by
default which can be upgraded to user tagging or it may support
tagging out of the box (receiver) with no option to pair the device to
an online user account. These are the possible combinations:

- Unidentified only
- Unidentified upgradeable to user
- Receiver only
- Receiver upgradeable to user

### No identity

Unidentified tagging is the minimal level of service. The broadcaster must
provide the following endpoint:

- [POST /tag](#post-tag)

A `POST` to this endpoint should return metadata relevant to the station
and time specified in the request. Tags are *not* stored on the server
so it is not possible to retrieve a list of tags on the receiver.

### Receiver identity

Receiver identity is designed to provide an "out-of-the-box"
experience without the user having to create an account and pair the
receiver. The protocol enables the receiver to become authorized to
store tags on the server without being associated with an
authenticated user account.

To indicate that it supports receiver identity, the server must issue
a `receiver` [grant](#authorization) in response to an unauthorized request
to `POST /tag`. It must provide the following endpoints:

- [POST /tag](#post-tag)
- [POST /token](#post-token)
- [GET /tags](#get-tags)

Tags are stored on the server. The server must be able to store at least
10 tags per receiver. There is no upper limit. A typical implementation
would store the tags as a FIFO list. When the list is full, a new tag
would replace the oldest in the list.

A receiver should implement an interface to display the current list of
tags associated with it as returned by the `GET /tags` method.

Note that with receiver identification, the receiver stores
a token which uniquely identifies it to the tag service for the
lifetime of that token only. If that identity is reset by the receiver
deleting the token, any tags which have been submitted against it are
effectively orphaned.

### User identity

User identity is where the receiver has been paired to an
authenticated user's account on a tag service. The same limits apply
as for receiver identification, though a typical implementation will
not put any limit on how many tags a user can create.

A tag service that enables tagging with a user identity must provide
the following endpoints:

- [POST /tag](#post-tag)
- [POST /token](#post-token)
- [GET /tags](#get-tags)
- [POST /registration\_key](#post-registration_key)
- [POST /register](#post-register)

### Authorization

Authorization is based on OAuth 2.0. The central concepts here are
**tokens** and **grants**.

To store or retrieve anything at the tag service, a receiver needs a
**token**. A valid token authorizes the receiver to perform a specific
set of actions. In the case of RadioTAG, those actions are to [create
a tag](#post-tag) or [get a list of tags](#get-tags) for either a
[receiver](#receiver-identity) identity or [user](#user-identity)
account identity.

To obtain a token, the receiver must use the **grant** passed back from
the server in a response header.

A **token** is like a key. If you have it in your hand, you can open the
door. A **grant** is like a chit giving you permission to request a key.
In the RadioTAG protocol, you can't do anything with a grant except
attempt to obtain the corresponding token.

## Glossary

---------------------------------------------------------------------------------------
Term               Definition
---------------    --------------------------------------------------------------------
Receiver           The device or user agent which interacts with the RadioTAG service

Receiver identity  A RadioTAG identity associated only with a specific receiver and
                   *not* with a user account

User identity      A RadioTAG identity where a receiver has been associated with a user
                   account, and which can then be accessed from any receiver which has
                   been similarly associated

Grant              Temporary permission to request a service

Scope              What a grant applies to

Auth Token         An authorization token which permits you to create a tag

Unix Time          The number of seconds elapsed since midnight Coordinated Universal
                   Time (UTC) on January 1, 1970, not counting leap seconds

--------------------------------------------------------------------------------------

## API

### Some general points

Requests pass information in a combination of HTTP headers and form
encoded POST parameters.

Responses pass data back in a combination of HTTP headers and XML.

While headers are shown here in a canonical form, due to the fact that
proxies and other intermediaries may adjust HTTP headers, both receiver
and server implementations should be prepared to accept header *keys*
in any mixture of upper and lower case. One common way to handle this
is to downcase all header keys on reading. Header *values* on the
other hand should not be changed by intermediaries and should be read
as is.

UTF-8 is the only supported character set.

### Common response headers

--------------------------------------------------------------------------------
Name                         Value
---------------------------  ---------------------------------------------------
RadioTAG-Service-Provider    The display name of the tag service provider

RadioTAG-Account-Name        The display name of the associated user account

RadioTAG-Auth-Token          The authorization token for a receiver or user
                             identity

--------------------------------------------------------------------------------

The `RadioTAG-Service-Provider` header should be returned in all
responses.

The `RadioTAG-Account-Name` should be returned in all responses to
requests made by a receiver that is paired with a user account.

The `RadioTAG-Auth-Token` header is returned when the receiver has been
granted authorization. It also enables the tag service to issue a new
token to replace an old one - see the next section.

### Updating tokens

The tag service can change the `RadioTAG-Auth-Token` in response to
any authorized request (i.e. one which contains a valid Auth Token). The
receiver should *always* use the last received Auth Token and update any
stored value from that. This provides a way for a tag service to expire
tokens.

We recommend that tag service implementations allow a period of grace in
which an expired token can co-exist with its replacement. This will
address the case where the token was updated but the response was not
received by the receiver.

### POST /tag

#### Request

##### Headers

--------------------------------------------------------------
Name                   Value
---------------------  ---------------------------------------
RadioTAG-Auth-Token    Empty OR receiver token OR user token

--------------------------------------------------------------

##### Parameters

--------------------------------------------------------------------------------
Name     Value
-------  -----------------------------------------------------------------------
station  RadioDNS broadcast parameters joined with dots, e.g.
         "0.c224.ce15.ce1.dab"

time     Whole number of seconds since 00:00a.m Jan 1 1970 UTC (Unix Epoch)

--------------------------------------------------------------------------------

#### Response

##### Status

--------------------------------------------------------------------------------
HTTP Status Code  HTTP Status   Explanation
----------------  ------------  ------------------------------------------------
200               OK            The service does not store tags but has returned
                                metadata in Atom format

201               Created       The service has stored the requested tag

401               Unauthorized  Unidentified tagging is not supported and the token
                                is blank or does not match either a receiver or
                                user identity

--------------------------------------------------------------------------------

##### Headers

-------------------------------------------------------------------------------
Name                         Value
---------------------------  --------------------------------------------------
RadioTAG-Service-Provider    The display name of the tag service provider

RadioTAG-Auth-Token          The token to use from now on.

RadioTAG-Account-Name        The display name of the associated user account.

RadioTAG-Grant-Scope         "receiver" or "identity". See [Authorization](#authorization).

RadioTAG-Grant-Token         The token to use when exercising the grant.

-------------------------------------------------------------------------------

A grant header is *not* returned in the following cases:

- the server supports only unidentified tagging
- the receiver is already using a user identity token
- the receiver is using a receiver identity token and the tag service doesn't
  support user accounts

##### Body

On a successful request (status 200 or 201), the body contains an Atom
feed containing a single entry representing the tag. See [Data
formats](#data-formats) below.

On an unsuccessful request, the body may be blank or may contain a short
explanation of why the request failed.

#### Example 1 - `POST /tag` with no token

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1312301004
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 401 Unauthorized↵
Date: Tue, 02 Aug 2011 16:03:24 GMT↵
Status: 401 Unauthorized↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: receiver↵
RadioTAG-Grant-Token: b86bfdfb-5ff5-4cc7-8c61-daaa4804f188↵
Content-Type: text/html;charset=utf-8↵
Content-Length: 18↵
↵
Must request token
~~~~

#### Example 2 - `POST /tag` with a valid receiver token

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: be222d22-4cef-439e-a77c-c867441dcb33↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1312301004
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Tue, 02 Aug 2011 16:03:25 GMT↵
Status: 201 Created↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 957↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>PM</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-02T17:03:24+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:fb669d2c-63b3-420b-9dd6-131f5d58e68a</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>PM</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b012wjd3_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b012wjd3?t=204"/>
    <id>urn:uuid:fb669d2c-63b3-420b-9dd6-131f5d58e68a</id>
    <updated>2011-08-02T17:03:24+01:00</updated>
    <published>2011-08-02T17:03:24+01:00</published>
    <summary>Eddie Mair presents the day's top stories.</summary>
  </entry>
</feed>
~~~~

Note that the response header contains the `RadioTAG-Grant-Scope`
`identity`. This will be present only if the service supports user
tagging.

#### Example 3 - `POST /tag` with a valid user token

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: b48bf7ed-14a6-429e-b5c8-35f7a4c094b7↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1312302129
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Tue, 02 Aug 2011 16:22:09 GMT↵
Status: 201 Created↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: b48bf7ed-14a6-429e-b5c8-35f7a4c094b7↵
RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 958↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>PM</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-02T17:22:09+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:8facc0c0-ce13-4349-8664-dc71d55c6c97</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>PM</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b012wjd3_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b012wjd3?t=1329"/>
    <id>urn:uuid:8facc0c0-ce13-4349-8664-dc71d55c6c97</id>
    <updated>2011-08-02T17:22:09+01:00</updated>
    <published>2011-08-02T17:22:09+01:00</published>
    <summary>Eddie Mair presents the day's top stories.</summary>
  </entry>
</feed>
~~~~

Note that the response header does not contain any grants but does
contain the paired user account name.

#### Example 4 - `POST /tag` against a service that does not provide receiver tagging

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1312195118
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Mon, 01 Aug 2011 10:38:38 GMT↵
Status: 200 OK↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 992↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Meet David Sedaris</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-01T11:38:38+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>Meet David Sedaris</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b01211y4_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b01211y4?t=518"/>
    <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
    <updated>2011-08-01T11:38:38+01:00</updated>
    <published>2011-08-01T11:38:38+01:00</published>
    <summary>'Me Talk Pretty One Day' and 'It's Catching'.</summary>
  </entry>
</feed>
~~~~

#### Example 5 - `POST /tag` against a service that provides only unidentified tagging

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1312195118
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Mon, 01 Aug 2011 10:38:38 GMT↵
Status: 200 OK↵
RadioTAG-Service-Provider: BBC↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 992↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Meet David Sedaris</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-01T11:38:38+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>Meet David Sedaris</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b01211y4_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b01211y4?t=518"/>
    <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
    <updated>2011-08-01T11:38:38+01:00</updated>
    <published>2011-08-01T11:38:38+01:00</published>
    <summary>'Me Talk Pretty One Day' and 'It's Catching'.</summary>
  </entry>
</feed>
~~~~

Note that no grant headers are issued.

### POST /token

#### Request

##### Headers

None.

##### Parameters

--------------------------------------------------------------------------------
Name          Value
------------  ------------------------------------------------------------------
grant\_scope  The value of the RadioTAG-Grant-Scope provided in the previous
              request

grant\_token  The value of the RadioTAG-Grant-Token provided in the previous
              request

--------------------------------------------------------------------------------

For more information, see [Authorization](#authorization).

##### Example

~~~~ {.example}
POST /token HTTP/1.1↵
Content-Length: 69↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=receiver&grant_token=b86bfdfb-5ff5-4cc7-8c61-daaa4804f188
~~~~

#### Response

##### Status

--------------------------------------------------------------------------------
HTTP Status Code  HTTP Status   Explanation
----------------  ------------  ------------------------------------------------
204               No Content    The token was successfully created

401               Unauthorized  The grant is missing or invalid

403               Forbidden     The grant is valid but the receiver is not allowed
                                to make this request

--------------------------------------------------------------------------------

##### Headers

-------------------------------------------------------------------------------
Name                         Value
---------------------------  --------------------------------------------------
RadioTAG-Service-Provider    The display name of the tag service provider

RadioTAG-Auth-Token          The newly issued token to use for future requests.

-------------------------------------------------------------------------------

##### Body

The `/token` endpoint should not return any content (as denoted by the
204 status code).

##### Example

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Tue, 02 Aug 2011 16:22:08 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: cf7ce9dc-7762-4b4c-970a-d194c5aa03ed↵
↵
~~~~

### GET /tags

#### Request

##### Headers

-----------------------------------------------------
Name                   Value
---------------------  ------------------------------
RadioTAG-Auth-Token    receiver token OR user token

-----------------------------------------------------

##### Parameters

----------------------------------------------------------------
Name                   Value
-----------   --------------------------------------------------
startIndex    (Optional) the 1-based index of the first result

itemsPerPage  (Optional) maximum number of entries to return

----------------------------------------------------------------

If the caller does not specify `startIndex`, it defaults to 1.

If the caller does not specify `itemsPerPage`, the number of entries
returned is determined by the server.

The server specifies the total number of entries that can be returned
in the result set using the `totalResults` element (see below).

Note: the `startIndex`, `itemsPerPage` and `totalResults` parameters
are based on the [OpenSearch
specification](http://www.oclc.org/developer/platform/query-responses).

##### Example

~~~~ {.example}
GET /tags HTTP/1.1↵
RadioTAG-Auth-Token: cf7ce9dc-7762-4b4c-970a-d194c5aa03ed↵
Host: radiotag.bbc.co.uk↵
↵
~~~~

#### Response

##### Status

--------------------------------------------------------------------------------
HTTP Status Code  HTTP Status   Explanation
----------------  ------------  ------------------------------------------------
200               OK            The request was successful

401               Unauthorized  The token is invalid or the service does not
                                allow storing of tags

--------------------------------------------------------------------------------

##### Headers

--------------------------------------------------------------------------------
Name                         Value
---------------------------  ---------------------------------------------------
RadioTAG-Account-Name        The display name of the associated user account
                             (if applicable)

RadioTAG-Service-Provider    The display name of the tag service provider

RadioTAG-Grant-Scope         If the service provides pairing to a user
                             account, this will have the value `identity`.
                             See [Authorization](#authorization)

RadioTAG-Grant-Token         The token to use when exercising the `identity`
                             grant

--------------------------------------------------------------------------------

##### Body

##### Example

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Tue, 02 Aug 2011 16:22:08 GMT↵
Status: 200 OK↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 974↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
       xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Tag List</title>
  <link href="http://radiotag.example.com/tags"/>
  <link href="http://radiotag.example.com/tags" rel="self"/>
  <updated>2011-08-02T17:22:08+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:6a041e97-65bb-4b12-82da-c1b373731905</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>PM</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b012wjd3_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b012wjd3?t=1328"/>
    <id>urn:uuid:9f61f2c1-f3f7-4ff7-bc61-32f0e468054d</id>
    <updated>2011-08-02T17:22:08+01:00</updated>
    <published>2011-08-02T17:22:08+01:00</published>
    <summary>Eddie Mair presents the day's top stories.</summary>
  </entry>
</feed>
~~~~

### POST /registration\_key

#### Request

##### Headers

-------------------------------------------------------------
Name                   Value
---------------------  --------------------------------------
RadioTAG-Auth-Token    Either blank or a valid receiver token

-------------------------------------------------------------

##### Parameters

--------------------------------------------------------------------
Name          Value
------------  ------------------------------------------------------
grant\_scope  Must be the value `identity`

grant\_token  Must be the grant token issued in the previous request

--------------------------------------------------------------------

##### Example

~~~~ {.example}
POST /registration_key HTTP/1.1↵
Content-Length: 73↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=identity&grant_token=ddc7f510-9353-45ad-9202-746ffe3b663a
~~~~

#### Response

##### Status

--------------------------------------------------------------------------------
HTTP Status Code  HTTP Status  Explanation
----------------  -----------  -------------------------------------------------
204               No Content   The request was successful. The response headers
                               contain the
                               registration key required to pair the radio.

--------------------------------------------------------------------------------

##### Headers

--------------------------------------------------------------------------------
Name                         Value
---------------------------  ---------------------------------------------------
RadioTAG-Service-Provider    The display name of the tag service provider

RadioTAG-Registration-Key    The registration key to use when pairing the
                             device.

RadioTAG-Registration-Url    The url to visit to register the device.

--------------------------------------------------------------------------------

##### Body

This response contains no body.

##### Example

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Tue, 02 Aug 2011 16:22:09 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Registration-Key: 2b188492↵
RadioTAG-Registration-Url: http://radiotag.example.com/↵
↵
~~~~

### POST /register

#### Request

##### Headers

-----------------------------------------------------
Name                   Value
---------------------  ------------------------------
RadioTAG-Auth-Token    Receiver OR user token

-----------------------------------------------------

##### Parameters

--------------------------------------------------------------------------------
Name               Value
-----------------  -------------------------------------------------------------
registration\_key  The registration key returned from the `/registration_key`
                   request

pin                The PIN issued to the user (e.g. at a web front end).

--------------------------------------------------------------------------------

##### Example

~~~~ {.example}
POST /register HTTP/1.1↵
RadioTAG-Auth-Token: cf7ce9dc-7762-4b4c-970a-d194c5aa03ed↵
Content-Length: 34↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
registration_key=2b188492&pin=3612
~~~~

#### Response

##### Status

--------------------------------------------------------------------------------
HTTP Status Code  HTTP Status  Explanation
----------------  -----------  -------------------------------------------------
204               No Content   The registration has succeeded and the receiver
                               has been paired to the associated user account

--------------------------------------------------------------------------------

##### Headers

------------------------------------------------------------------------------
Name                         Value
---------------------------  -------------------------------------------------
RadioTAG-Service-Provider    The display name of the tag service provider

RadioTAG-Auth-Token          The token to use for future requests

RadioTAG-Account-Name        The display name of the associated user account

------------------------------------------------------------------------------

##### Body

There is no body returned in this response.

##### Example

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Tue, 02 Aug 2011 16:22:09 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: b48bf7ed-14a6-429e-b5c8-35f7a4c094b7↵
RadioTAG-Account-Name: sean↵
↵
~~~~

## Data formats

### Tag data

All server responses containing tags use the [Atom Syndication
Format](http://tools.ietf.org/html/rfc4287) to represent tags, with some
extensions under a `RadioTAG` namespace.

In the following, the element prefix "radiotag:" indicates the RadioTag
namespace. All other elements are assumed to be from the Atom namespace.

Atom defines these elements as required:

-----------------------------------------------------------------------------
Element  Description                                               Max length
-------  --------------------------------------------------------  ----------
id       unique identifier for this tag                            48
         [ref](http://tools.ietf.org/html/rfc4287#section-4.2.6)

title    broadcaster generated title                               128
         [ref](http://tools.ietf.org/html/rfc4287#section-4.2.14)

updated  the datetime the tag was modified                         20
         [ref](http://tools.ietf.org/html/rfc4287#section-4.2.15)

-----------------------------------------------------------------------------

All dates are UTC in ISO format ([ISO
8601](http://en.wikipedia.org/wiki/ISO8601) or [RFC
3339](http://tools.ietf.org/html/rfc3339)), e.g. `2011-08-08T09:00:00Z`.

The RadioTAG specification also requires the following:

-----------------------------------------------------------------------------
Element           Description                                      Max length
----------------  -----------------------------------------------  ----------
author            name of tag service provider (e.g. BBC, Global)  16

published         the datetime of creation (= tag time)            20

summary           text only - i.e. must not include HTML tags      180

link rel="image"  link to 100x100 image representing the tag       255

link rel="self"   a user accessible url for the tag                255

radiotag:service  the human-readable name of the service tagged    16

radiotag:sid      RadioDNS service identifier                      32

-----------------------------------------------------------------------------

Note the difference here between `id` and `link rel="self"`. `id` is a
globally unique identifier. `link rel="self"` gives the url as visible
to the device/user (i.e. scoped by the auth token).

Also note that we are interpreting the `published` entry as equivalent
to the tag time. The `updated` element can be used to indicate that the
tag data has been updated, e.g. the description has changed.

The 255 character limit on urls is based on a strict reading of the note
in paragraph 3 of [RFC 2616 Section
3.2.1](http://tools.ietf.org/html/rfc2616#section-3.2.1).

The `radiotag:service` limit matches the `mediumNameType` in the EPG
specifications (and also the DAB label length).

The example below shows these elements in context:

~~~~ {.example}
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Meet David Sedaris</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-01T11:38:38+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>Meet David Sedaris</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b01211y4_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b01211y4?t=518"/>
    <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
    <updated>2011-08-01T11:38:38+01:00</updated>
    <published>2011-08-01T11:38:38+01:00</published>
    <summary>'Me Talk Pretty One Day' and 'It's Catching'.</summary>
  </entry>
</feed>
~~~~

### Tags data

~~~~ {.example}
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Tag List</title>
  <link href="http://radiotag.example.com/tags"/>
  <link href="http://radiotag.example.com/tags" rel="self"/>
  <updated>2011-08-02T17:22:09+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:bf3e7d30-ccb8-4b45-b438-c790fb2ec5f7</id>
  <os:totalResults>3</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>3</os:itemsPerPage>
  <entry>
    <title>PM</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b012wjd3_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b012wjd3?t=1329"/>
    <id>urn:uuid:8facc0c0-ce13-4349-8664-dc71d55c6c97</id>
    <updated>2011-08-02T17:22:09+01:00</updated>
    <published>2011-08-02T17:22:09+01:00</published>
    <summary>Eddie Mair presents the day's top stories.</summary>
  </entry>
  <entry>
    <title>PM</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b012wjd3_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b012wjd3?t=1328"/>
    <id>urn:uuid:9f61f2c1-f3f7-4ff7-bc61-32f0e468054d</id>
    <updated>2011-08-02T17:22:08+01:00</updated>
    <published>2011-08-02T17:22:08+01:00</published>
    <summary>Eddie Mair presents the day's top stories.</summary>
  </entry>
  <entry>
    <title>PM</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://node1.bbcimg.co.uk/iplayer/images/episode/b012wjd3_150_84.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b012wjd3?t=1328"/>
    <id>urn:uuid:8e67aef6-4e8c-47ac-bc10-f89d4d5bac17</id>
    <updated>2011-08-02T17:22:08+01:00</updated>
    <published>2011-08-02T17:22:08+01:00</published>
    <summary>Eddie Mair presents the day's top stories.</summary>
  </entry>
</feed>
~~~~

## Limits

### Data elements

----------------------------------------------------------------------------------------------
Data element      Max. size in bytes  Notes
----------------  ------------------  --------------------------------------------------------
author            16                  Atom entry

id                48                  Atom entry

pin number        10

service id (sid)  32                  As specified by RadioDNS

summary           180                 Atom entry

title             128                 Atom entry (compatible with DAB/RDS Livetext)

token             48

url               255                 See [RFC 2616 Section
                                      3.2.1](http://tools.ietf.org/html/rfc2616#section-3.2.1)

----------------------------------------------------------------------------------------------

### HTTP Headers

-----------------------------------------------
Headers                      Max. size in bytes
---------------------------  ------------------
RadioTAG-Account-Name        48

RadioTAG-Auth-Token          48

RadioTAG-Grant-Scope         16

RadioTAG-Grant-Token         48

RadioTAG-Registration-Key    10

RadioTAG-Registration-Url    128

RadioTAG-Service-Provider    16

-----------------------------------------------

# Appendix

## Narratives

### From receiver to user pairing

This section describes the requests and responses made between a
receiver and a RadioTAG server when the server supports both receiver
and user tagging.

#### Tune radio to BBC Radio 4

After tuning to BBC Radio 4, a RadioDNS look-up is performed to resolve
the broadcast parameters into a `hostname` for the RadioTAG service.

Having ascertained that the service supports RadioTAG, the receiver makes
available a `Tag` button.

#### Press tag

The user presses the `Tag` button.

##### Request

The receiver makes a POST request to the tag service with the `station`
identifier (using the broadcast parameter string used in constructing a
RadioDNS FQDN), and a `time`. Unix Time is used for the `time`
parameter.

As this receiver has no Auth Token, the `Radiotag-Auth-Token` header is
blank. It could also simply not be there at all. The following sequence
of events is also triggered when the request contains an invalid
authentication token.

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319201989
~~~~

##### Response

To mitigate the possibility of resource depletion attacks, when the
server supports receiver tagging we introduce a two-step process to
obtain a token before being allowed to tag. The first step involves
obtaining a **grant**. A grant is temporary permission to make a
specific request.

When a tag service supports receiver tagging, it responds to an
unauthenticated `/tag` request by returning a `401 Unauthorized`
response containing a grant that allows the device to request an
authentication token. This grant consists of two parts: a **scope**
which indicates that the server supports receiver tagging, and a
**token** which is used in the subsequent request to `/token`.

A general principle is that a grant is only guaranteed to be valid on
the next request, so should not be stored permanently.

~~~~ {.example}
HTTP/1.1 401 Unauthorized↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 401 Unauthorized↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: receiver↵
RadioTAG-Grant-Token: b86bfdfb-5ff5-4cc7-8c61-daaa4804f188↵
Content-Type: text/html;charset=utf-8↵
Content-Length: 18↵
↵
Must request token
~~~~

##### Request

The receiver POSTs the grant to the `/token` endpoint to request a token
to create tags.

~~~~ {.example}
POST /token HTTP/1.1↵
Content-Length: 69↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=receiver&grant_token=b86bfdfb-5ff5-4cc7-8c61-daaa4804f188
~~~~

##### Response

The authentication token is returned to the receiver in the headers of a
`204 No Content` response.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
↵
~~~~

##### Request

Now the receiver has successfully exchanged a grant for a token, the tag
request can be made again, this time passing the authentication token in
a header of a POST request to `/tag`.

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319201989
~~~~

##### Response

The server verifies the request by checking the token against those that
it has issued, and if valid creates a tag. The metadata corresponding to
this tag is returned in the body of a `201 Created` response, in the
form of an [Atom](http://tools.ietf.org/html/rfc4287) document. See
[Data formats](#data-formats) for more details.

An example entry for a tag created during an episode of a BBC Radio 4
programme is shown below:

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 201 Created↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1032↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Feedback</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T13:59:49+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:661417da-cb8d-4fd0-a8fd-9b55ed2086d7</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>Feedback</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zsx2.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zsx2?t=1789"/>
    <id>urn:uuid:661417da-cb8d-4fd0-a8fd-9b55ed2086d7</id>
    <updated>2011-10-21T13:59:49+01:00</updated>
    <published>2011-10-21T13:59:49+01:00</published>
    <summary>Listener views on local radio cuts. Roger hears how to secure inclusion on R4's Last Word.</summary>
  </entry>
</feed>
~~~~

#### Press OK

In the previous, successful `/tag` request, the server's response
contained a `identity` grant. The presence of this grant indicates
to the receiver that the server supports the pairing a receiver with a user
account. At this stage the receiver can present to the user the option to
register with the server, or to accept the information in the current
tag and return to the default state for the station.

In this case, we chose the latter by pressing `OK`.

#### Press Tags

As the server supports receiver tagging the tags created so far have
been stored on the server against the authentication token, which stands
in for a receiver id. The receiver can request a list of tags by making a
GET request to `/tags` with the authentication token in the header:

##### Request

~~~~ {.example}
GET /tags HTTP/1.1↵
RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
Host: radiotag.bbc.co.uk↵
↵
~~~~

##### Response

The server responds with an Atom feed containing a list of tags created
for this device.

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 200 OK↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1042↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Tag List</title>
  <link href="http://radiotag.bbc.co.uk/tags"/>
  <link href="http://radiotag.bbc.co.uk/tags" rel="self"/>
  <updated>2011-10-21T13:59:49+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:8eca1859-bb85-4c23-ba06-d078f6bfc9f5</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>Feedback</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zsx2.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zsx2?t=1789"/>
    <id>urn:uuid:661417da-cb8d-4fd0-a8fd-9b55ed2086d7</id>
    <updated>2011-10-21T13:59:49+01:00</updated>
    <published>2011-10-21T13:59:49+01:00</published>
    <summary>Listener views on local radio cuts. Roger hears how to secure inclusion on R4's Last Word.</summary>
  </entry>
</feed>
~~~~

#### Press Tag

We now show the flow of interactions when a user decides to register
their receiver with the service. The process begins with the user pressing
the `Tag` button as before.

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319201989
~~~~

##### Response

The response in this case is a `201 Created`, since the service supports
receiver tagging and the receiver has passed in the authentication token
with the request to `/tag`. Again the response contains a `identity`
grant. The receiver uses the presence of this grant to decide to display
the option to register.

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 201 Created↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1032↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Feedback</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T13:59:49+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:4b8a1b72-f76b-4dc2-9db8-cb15042454ea</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>Feedback</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zsx2.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zsx2?t=1789"/>
    <id>urn:uuid:4b8a1b72-f76b-4dc2-9db8-cb15042454ea</id>
    <updated>2011-10-21T13:59:49+01:00</updated>
    <published>2011-10-21T13:59:49+01:00</published>
    <summary>Listener views on local radio cuts. Roger hears how to secure inclusion on R4's Last Word.</summary>
  </entry>
</feed>
~~~~

#### Press Register

This time the user selects the option to register on the receiver. The
receiver requires an identifier to identify itself to the server during
the registration process. It requests this from the tag service by
making a POST request to the `/registration_key` endpoint, sending back
the `grant_scope` and `grant_token` from the previous response.

##### Request

~~~~ {.example}
POST /registration_key HTTP/1.1↵
Content-Length: 73↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=identity&grant_token=ddc7f510-9353-45ad-9202-746ffe3b663a
~~~~

##### Response

The service responds with a registration key in the header, and the
location of a web site where the user can complete the registration
process.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Registration-Key: 399eaa7c↵
RadioTAG-Registration-Url: http://radiotag.bbc.co.uk/↵
↵
~~~~

#### Register with a web front end

Registering with a web front end and obtaining the authenticating PIN
number is outside the scope of RadioTAG, so is not specified here.

The following is a sketch of how this part of the system might be
implemented:

> The desired outcome of registering is that the registration key is
> associated with a user's account and a PIN returned to the user. The
> combination of registration key (which is already known to the receiver)
> and the PIN will be used to request an authenticated token in the
> `/register` step below. The tag service needs then to be able to map
> that token to the corresponding user account.
>
> A typical scenario would be that the user visits the broadcaster's web
> front end, authenticates by some means with the provider of the
> tagging service (using their user name and password, for example), and
> submits the registration key obtained in the previous step using a
> form.
>
> This causes a request to be made to the service which has previously
> stored the registration key that was issued to the receiver in the
> previous step. The service then checks the authenticity and, if valid,
> issues a PIN number, which is then displayed to the user.
>
> At the backend, the registration key and PIN are stored against the
> user account so that when the `/register` request is made, they can be
> validated and exchanged for a token.

#### Enter the PIN

The user enters the PIN number obtained in the previous step into their
receiver, which then makes a POST request to `/register` with the
registration key and PIN in the body of the request.

Note that the previously issued authentication token for receiver
tagging is included in the header of the request. This allows the server
to migrate tags from an unpaired receiver to the user's account.

##### Request

~~~~ {.example}
POST /register HTTP/1.1↵
RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
Content-Length: 34↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
registration_key=399eaa7c&pin=7535
~~~~

##### Response

The server checks the credentials and returns `204 No Content` to
indicate that a new token has been created. The response headers contain
the new authentication token (`RadioTAG-Auth-Token`), which is to be
used for future tagging requests that wish to be associated with this
user account. Also in the headers is the user account name
(`RadioTAG-Account-Name`). This account name can be used by the receiver
to provide a reminder or prompt to the user in case they are unsure of
the account they used to register the receiver.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 12:59:50 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
RadioTAG-Account-Name: sean↵
↵
~~~~

#### Press Tag

The receiver now has a token which identifies the receiver with the user
account on the server. Subsequent tag requests are made as POSTs to
`/tag` with this token sent in the request headers, so that they can be
stored against the user's account.

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319201990
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Fri, 21 Oct 2011 12:59:50 GMT↵
Status: 201 Created↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1032↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Feedback</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T13:59:50+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5967db0e-dc63-428d-a075-90cf316ded5d</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>Feedback</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zsx2.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zsx2?t=1790"/>
    <id>urn:uuid:5967db0e-dc63-428d-a075-90cf316ded5d</id>
    <updated>2011-10-21T13:59:50+01:00</updated>
    <published>2011-10-21T13:59:50+01:00</published>
    <summary>Listener views on local radio cuts. Roger hears how to secure inclusion on R4's Last Word.</summary>
  </entry>
</feed>
~~~~

#### Press Tags

The receiver can again request a list of tags, this time using the new
authentication token. The server has migrated the tags created while the
receiver was unpaired to the user's account, so all three tags created
above are returned in the Atom feed.

##### Request

~~~~ {.example}
GET /tags HTTP/1.1↵
RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
Host: radiotag.bbc.co.uk↵
↵
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Fri, 21 Oct 2011 12:59:50 GMT↵
Status: 200 OK↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 2268↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>Tag List</title>
  <link href="http://radiotag.bbc.co.uk/tags"/>
  <link href="http://radiotag.bbc.co.uk/tags" rel="self"/>
  <updated>2011-10-21T13:59:50+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:93beb9c2-0b8d-49ad-a813-c1e6120f63b9</id>
  <os:totalResults>3</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>3</os:itemsPerPage>
  <entry>
    <title>Feedback</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zsx2.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zsx2?t=1790"/>
    <id>urn:uuid:5967db0e-dc63-428d-a075-90cf316ded5d</id>
    <updated>2011-10-21T13:59:50+01:00</updated>
    <published>2011-10-21T13:59:50+01:00</published>
    <summary>Listener views on local radio cuts. Roger hears how to secure inclusion on R4's Last Word.</summary>
  </entry>
  <entry>
    <title>Feedback</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zsx2.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zsx2?t=1789"/>
    <id>urn:uuid:4b8a1b72-f76b-4dc2-9db8-cb15042454ea</id>
    <updated>2011-10-21T13:59:49+01:00</updated>
    <published>2011-10-21T13:59:49+01:00</published>
    <summary>Listener views on local radio cuts. Roger hears how to secure inclusion on R4's Last Word.</summary>
  </entry>
  <entry>
    <title>Feedback</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zsx2.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zsx2?t=1789"/>
    <id>urn:uuid:661417da-cb8d-4fd0-a8fd-9b55ed2086d7</id>
    <updated>2011-10-21T13:59:49+01:00</updated>
    <published>2011-10-21T13:59:49+01:00</published>
    <summary>Listener views on local radio cuts. Roger hears how to secure inclusion on R4's Last Word.</summary>
  </entry>
</feed>
~~~~

### Unidentified to user identity

This section shows the HTTP traces of transactions between a RadioTAG
receiver (e.g. a radio) and a RadioTAG service. It covers the scenario
where the RadioTAG service permits *unidentified* tagging upgradeable
to *user* account tagging, i.e. it provides a response to an
unauthorized receiver but does not store tags until the receiver has
been paired with a user account.

Here we deal only with the differences between this scenario and the
receiver-to-user scenario above. Please refer to that document for
more information.

#### Press Tag

The user presses the `Tag` button. Note that the request is exactly the
same as in the receiver case above.

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319202059
~~~~

##### Response

The response is a `200 OK` rather than a `201 Created`. The receiver
should remember this result for later as it indicates that the receiver
should resubmit the tag request after registration.

Note that just like the receiver case, the response contains a
`identity` grant. The receiver can use this to provide the choice to
accept the result or to register the receiver.

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Fri, 21 Oct 2011 13:00:59 GMT↵
Status: 200 OK↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 973↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>The Archers</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T14:00:59+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:3bfaa9dd-11ed-45f9-8f3c-6587db086b04</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>The Archers</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zs13.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zs13?t=59"/>
    <id>urn:uuid:3bfaa9dd-11ed-45f9-8f3c-6587db086b04</id>
    <updated>2011-10-21T14:00:59+01:00</updated>
    <published>2011-10-21T14:00:59+01:00</published>
    <summary>David brings shocking news.</summary>
  </entry>
</feed>
~~~~

#### Press OK

At this point, the receiver can forget the stored `200 OK` result code.

#### Press Tags

##### Request

~~~~ {.example}
GET /tags HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Host: radiotag.bbc.co.uk↵
↵
~~~~

##### Response

As this service does not provide receiver tagging, there are no tags
stored on the server.

~~~~ {.example}
HTTP/1.1 401 Unauthorized↵
Date: Fri, 21 Oct 2011 13:00:59 GMT↵
Status: 401 Unauthorized↵
RadioTAG-Service-Provider: BBC↵
Content-Type: text/html;charset=utf-8↵
Content-Length: 12↵
↵
Unauthorized
~~~~

#### Press Tag

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319202059
~~~~

##### Response

Again, the receiver should remember that the return code for this `/tag`
request is 200.

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Fri, 21 Oct 2011 13:01:00 GMT↵
Status: 200 OK↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Grant-Scope: identity↵
RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 973↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>The Archers</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T14:00:59+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:8ea43558-70c2-4a4a-aeb9-8ffeee700898</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>The Archers</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zs13.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zs13?t=59"/>
    <id>urn:uuid:8ea43558-70c2-4a4a-aeb9-8ffeee700898</id>
    <updated>2011-10-21T14:00:59+01:00</updated>
    <published>2011-10-21T14:00:59+01:00</published>
    <summary>David brings shocking news.</summary>
  </entry>
</feed>
~~~~

#### Press Register

##### Request

~~~~ {.example}
POST /registration_key HTTP/1.1↵
Content-Length: 73↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=identity&grant_token=ddc7f510-9353-45ad-9202-746ffe3b663a
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 13:01:00 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Registration-Key: 4fa9ed43↵
RadioTAG-Registration-Url: http://radiotag.bbc.co.uk/↵
↵
~~~~

#### Register with the web front end to get a PIN

Registering with a web front end is outside the scope of the RadioTAG
specification. See the note on [registering with a web front
end](#register-with-a-web-front-end) above for one possible
implementation.

#### Enter PIN

##### Request

Note that unlike the receiver case, there is no auth token to send.

~~~~ {.example}
POST /register HTTP/1.1↵
RadioTAG-Auth-Token: ↵
Content-Length: 34↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
registration_key=4fa9ed43&pin=9666
~~~~

##### Response

The receiver has now completed the pairing process so receives an
`RadioTAG-Auth-Token` header which it should include as a request
header in all future requests.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 13:01:00 GMT↵
Status: 204 No Content↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: 0f73d1b8-e6b5-451e-9ecf-1a3c33c76415↵
RadioTAG-Account-Name: sean↵
↵
~~~~

##### Request

The receiver should have stored the result of the previous request to
`/tag`. As it was a `200 OK` rather than `201 Created`, the receiver knows
it should resubmit the tag request, this time including the newly
acquired `RadioTAG-Auth-Token` in the request header:

~~~~ {.example}
POST /tag HTTP/1.1↵
RadioTAG-Auth-Token: 0f73d1b8-e6b5-451e-9ecf-1a3c33c76415↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319202060
~~~~

##### Response

This time the response status is `201 Created` to indicate that the tag
data has been stored on the server and can be retrieved both on the
device and via the web.

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Fri, 21 Oct 2011 13:01:00 GMT↵
Status: 201 Created↵
RadioTAG-Service-Provider: BBC↵
RadioTAG-Auth-Token: 0f73d1b8-e6b5-451e-9ecf-1a3c33c76415↵
RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 973↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag"
      xmlns:os="http://a9.com/-/spec/opensearch/1.1/">
  <title>The Archers</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T14:01:00+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:fcbb6008-aa54-45b4-91c9-78ec0655f9d7</id>
  <os:totalResults>1</os:totalResults>
  <os:startIndex>1</os:startIndex>
  <os:itemsPerPage>1</os:itemsPerPage>
  <entry>
    <title>The Archers</title>
    <radiotag:sid>0.c224.ce15.ce1.dab</radiotag:sid>
    <radiotag:service>BBC Radio 4</radiotag:service>
    <link rel="image" href="http://radiotag.bbc.co.uk/images/episode/b015zs13.jpg"/>
    <link rel="canonical" href="http://www.bbc.co.uk/programmes/b015zs13?t=60"/>
    <id>urn:uuid:fcbb6008-aa54-45b4-91c9-78ec0655f9d7</id>
    <updated>2011-10-21T14:01:00+01:00</updated>
    <published>2011-10-21T14:01:00+01:00</published>
    <summary>David brings shocking news.</summary>
  </entry>
</feed>
~~~~
