% RadioTAG 1.00 specification, draft 4
% Sean O'Halpin (BBC R&D); Chris Lowis (BBC R&D)
% 2012-06-13

### Authors

Sean O'Halpin (BBC R&D), Chris Lowis (BBC R&D)

### Contributors

Andy Buckingham (Global Media), Robin Cooksey (Frontier Silicon)

### Published

- Draft 1: 2011-09-01
- Draft 2: 2011-10-27
- Draft 3: 2012-02-08
    - Changed /register return code from 201 to 204
- Draft 4: 2012-06-13
    - Conversion to pandoc markdown format

### URL

[http://radiotag.prototyping.bbc.co.uk/docs/radiotag-api-proposal-v1.00d4.html](http://radiotag.prototyping.bbc.co.uk/docs/radiotag-api-proposal-v1.00d3.html)

## Abstract

This document specifies version 1.00 of the RadioTAG protocol.

The RadioTAG protocol defines how a client (e.g. an IP-enabled radio)
discovers whether a broadcaster supports RadioTAG and if so how it then
communicates with a broadcaster-provided web service to record the time
and station being listened to.

The protocol defines how a client obtains authorization to store data on
the server and how it can become paired with a user account so that data
can be accessed via the web.

The protocol also defines the format and content of the requests and
responses that pass between the client and server.

## How to read this document

The document starts with an overview of the [concepts](#sec-3)
underlying the RadioTAG protocol. These concepts are summarized in the
[glossary](#sec-4).

To get an idea of how the RadioTAG protocol works in practice, read the
two [narratives](#sec-5). These step through the two most common
scenarios to show what is communicated between the client (radio) and
the tag service at the HTTP level. This section is particularly useful
for developers who want to understand how the various bits of the API
hang together.

For full details about each endpoint provided by the tag service, read
the [API](#sec-6) section.

Finally, to see how the Atom format is used in tag responses, what each
element contains and what limits apply, see [data formats](#sec-7).

## Concepts

A client sends a tag request to a tag service, specifying a time and
station. The tag service responds by sending a tag entry containing
relevant metadata. The tag data may be stored on the server and may be
viewed on the client or on the web or be used for another application.

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

The content of the *response* to a tag request is up to the broadcaster
but must follow the [Atom Syndication
Format](http://tools.ietf.org/html/rfc4287) as [specified
below](#sec-7). A tag response could contain programme, now playing
metadata, an advertising message or the response to a call for action.

### Clients, radios and devices

In this specification, the **client** is any device or software program
that implements the client side of the RadioTAG specification. While
this would most commonly be an IP-enabled radio, it could also be, say,
an application running on a mobile phone or in a web browser.

### The tag service

The **tag service** is the web service provided by the broadcaster to
respond to client requests. It must implement a number of endpoints
depending on the level of service it provides.

### Levels of service

There are three levels of service a tag service can provide:

- anonymous tagging
- unpaired tagging
- paired tagging

Pairing in this context means associating your radio with an
authenticated user account.

The levels of service are distinguished by whether or not tags are
retrievable on the device or on the web and by whether you need an
account on the broadcaster's web service. The table below summarizes the
differences:

---------------------------------------------------------------------
Level of service  Tag list on device  Tag list on web  Account needed
----------------  ------------------  ---------------  --------------
Anonymous         No                  No               No

Unpaired          Yes                 No               No

Paired            Yes                 Yes              Yes

---------------------------------------------------------------------

These services can be offered in a number of combinations. For example,
a service may offer anonymous tagging by default which can be upgraded
to paired tagging or it may support tagging out of the box (unpaired)
with no option to pair the device to a web account. These are the
possible combinations:

- Anonymous only
- Anonymous upgradeable to paired
- Unpaired only
- Unpaired upgradeable to paired

### Anonymous tagging

Anonymous tagging is the minimal level of service. The broadcaster must
provide the following endpoint:

- [POST /tag](#sec-6-4)

A `POST` to this endpoint should return metadata relevant to the station
and time specified in the request. Tags are *not* stored on the server
so it is not possible to retrieve a list of tags on the client.

### Unpaired tagging

Unpaired tagging is designed to provide an "out-of-the-box" experience
without the user having to create an account and pair the client. The
protocol enables the client to become authorized to store tags on the
server without being associated with an authenticated user account.

To indicate that it supports unpaired tagging, the server must issue an
`unpaired` [grant](#Grants) in response to an unauthorized request to
`POST /tag`. It must provide the following endpoints:

- [POST /tag](#sec-6-4)
- [POST /token](#sec-6-5)
- [GET /tags](#sec-6-6)

Tags are stored on the server. The server must be able to store at least
10 tags per client. There is no upper limit. A typical implementation
would store the tags as a FIFO list. When the list is full, a new tag
would replace the oldest in the list.

A client should implement an interface to display the current list of
tags associated with it as returned by the `GET /tags` method.

Note that with unpaired tagging, the client stores a token which
uniquely identifies it to the tag service for the lifetime of that token
only. If that identity is reset by the client deleting the token, any
tags which have been submitted against it are effectively orphaned.

### Paired tagging

Paired tagging is where the client has been paired to a user's account
on a tag service. The same limits apply as for unpaired tagging, though
a typical implementation will not put any limit on how many tags a user
can create.

A tag service that allows paired tagging must provide the following
endpoints:

- [POST /tag](#sec-6-4)
- [POST /token](#sec-6-5)
- [GET /tags](#sec-6-6)
- [POST /registration\_key](#sec-6-7)
- [POST /register](#sec-6-8)

### Authorization

Authorization is based on OAuth 2.0. The central concepts here are
**tokens** and **grants**.

To store or retrieve anything at the tag service, a client needs a
**token**. A valid token authorizes the client to perform a specific set
of actions. In the case of RadioTAG, those actions are to [create a
tag](#sec-6-4) or [get a list of tags](#sec-6-6) for either an
[unpaired](#sec-3-9) or [paired](#sec-3-10) account.

To obtain a token, the client must use the **grant** passed back from
the server in a response header.

A **token** is like a key. If you have it in your hand, you can open the
door. A **grant** is like a chit giving you permission to request a key.
In the RadioTAG protocol, you can't do anything with a grant except
attempt to obtain the corresponding token.

## Glossary

--------------------------------------------------------------------------------
Term        Definition
----------  --------------------------------------------------------------------
Unpaired    Where a device has not been associated with a user account

Paired      Where a device has been associated with a user account

Grant       Temporary permission to request a service

Scope       What a grant applies to

Auth Token  An authorization token which permits you to create a tag

Unix Time   The number of seconds elapsed since midnight Coordinated Universal
            Time
            (UTC) on January 1, 1970, not counting leap seconds

--------------------------------------------------------------------------------

## Narratives

### Unpaired to paired

This section describes the requests and responses made between a client
and a RadioTAG server when the server supports both unpaired and paired
tagging.

#### Tune radio to BBC Radio 4

After tuning to BBC Radio 4, a RadioDNS look-up is performed to resolve
the broadcast parameters into a `hostname` for the RadioTAG service.

Having ascertained that the service supports RadioTAG, the client makes
available a `Tag` button.

#### Press tag

The user presses the `Tag` button.

##### Request

The client makes a POST request to the tag service with the `station`
identifier (using the broadcast parameter string used in constructing a
RadioDNS FQDN), and a `time`. Unix Time is used for the `time`
parameter.

As this client has no Auth Token, the `X-Radiotag-Auth-Token` header is
blank. It could also simply not be there at all. The following sequence
of events is also triggered when the request contains an invalid
authentication token.

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319201989
~~~~

##### Response

To mitigate the possibility of resource depletion attacks, when the
server supports unpaired tagging we introduce a two-step process to
obtain a token before being allowed to tag. The first step involves
obtaining a **grant**. A grant is temporary permission to make a
specific request.

When a tag service supports unpaired tagging, it responds to an
unauthenticated `/tag` request by returning a `401 Unauthorized`
response containing a grant that allows the device to request an
authentication token. This grant consists of two parts: a **scope**
which indicates that the server supports unpaired tagging, and a
**token** which is used in the subsequent request to `/token`.

A general principle is that a grant is only guaranteed to be valid on
the next request, so should not be stored permanently.

~~~~ {.example}
HTTP/1.1 401 Unauthorized↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 401 Unauthorized↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: unpaired↵
X-RadioTAG-Grant-Token: b86bfdfb-5ff5-4cc7-8c61-daaa4804f188↵
Content-Type: text/html;charset=utf-8↵
Content-Length: 18↵
↵
Must request token
~~~~

##### Request

The client POSTs the grant to the `/token` endpoint to request a token
to create tags.

~~~~ {.example}
POST /token HTTP/1.1↵
Content-Length: 69↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=unpaired&grant_token=b86bfdfb-5ff5-4cc7-8c61-daaa4804f188
~~~~

##### Response

The authentication token is returned to the client in the headers of a
`204 No Content` response.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
↵
~~~~

##### Request

Now the client has successfully exchanged a grant for a token, the tag
request can be made again, this time passing the authentication token in
a header of a POST request to `/tag`.

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
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
[Data formats](#sec-7) for more details.

An example entry for a tag created during an episode of a BBC Radio 4
programme is shown below:

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 201 Created↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1032↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Feedback</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T13:59:49+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:661417da-cb8d-4fd0-a8fd-9b55ed2086d7</id>
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
contained a `can_register` grant. The presence of this grant indicates
to the client that the server supports the pairing a client with a user
account. At this stage the client can present to the user the option to
register with the server, or to accept the information in the current
tag and return to the default state for the station.

In this case, we chose the latter by pressing `OK`.

#### Press Tags

As the server supports unpaired tagging the tags created so far have
been stored on the server against the authentication token, which stands
in for a client id. The client can request a list of tags by making a
GET request to `/tags` with the authentication token in the header:

##### Request

~~~~ {.example}
GET /tags HTTP/1.1↵
X-RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
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
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1042↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Tag List</title>
  <link href="http://radiotag.bbc.co.uk/tags"/>
  <link href="http://radiotag.bbc.co.uk/tags" rel="self"/>
  <updated>2011-10-21T13:59:49+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:8eca1859-bb85-4c23-ba06-d078f6bfc9f5</id>
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
their client with the service. The process begins with the user pressing
the `Tag` button as before.

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319201989
~~~~

##### Response

The response in this case is a `201 Created`, since the service supports
unpaired tagging and the client has passed in the authentication token
with the request to `/tag`. Again the response contains a `can_register`
grant. The client uses the presence of this grant to decide to display
the option to register.

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 201 Created↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1032↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Feedback</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T13:59:49+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:4b8a1b72-f76b-4dc2-9db8-cb15042454ea</id>
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

This time the user selects the option to register on the client. The
client requires an identifier to identify itself to the server during
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
grant_scope=can_register&grant_token=ddc7f510-9353-45ad-9202-746ffe3b663a
~~~~

##### Response

The service responds with a registration key in the header, and the
location of a web site where the user can complete the registration
process.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 12:59:49 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Registration-Key: 399eaa7c↵
X-RadioTAG-Registration-Url: http://radiotag.bbc.co.uk/↵
↵
~~~~

#### Register with a web front end

Registering with a web front end and obtaining the authenticating PIN
number is outside the scope of RadioTAG, so is not specified here.

The following is a sketch of how this part of the system might be
implemented:

> The desired outcome of registering is that the registration key is
> associated with a user's account and a PIN returned to the user. The
> combination of registration key (which is already known to the client)
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
> stored the registration key that was issued to the client in the
> previous step. The service then checks the authenticity and, if valid,
> issues a PIN number, which is then displayed to the user.
>
> At the backend, the registration key and PIN are stored against the
> user account so that when the `/register` request is made, they can be
> validated and exchanged for a token.

#### Enter the PIN

The user enters the PIN number obtained in the previous step into their
client, which then makes a POST request to `/register` with the
registration key and PIN in the body of the request.

Note that the previously issued authentication token for unpaired
tagging is included in the header of the request. This allows the server
to migrate tags from an unpaired client to the user's account.

##### Request

~~~~ {.example}
POST /register HTTP/1.1↵
X-RadioTAG-Auth-Token: e2300af3-bad6-45f8-ba38-6bcb025ca210↵
Content-Length: 34↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
registration_key=399eaa7c&pin=7535
~~~~

##### Response

The server checks the credentials and returns `204 No Content` to
indicate that a new token has been created. The response headers contain
the new authentication token (`X-RadioTAG-Auth-Token`), which is to be
used for future tagging requests that wish to be associated with this
user account. Also in the headers is the user account name
(`X-RadioTAG-Account-Name`). This account name can be used by the client
to provide a reminder or prompt to the user in case they are unsure of
the account they used to register the client.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 12:59:50 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
X-RadioTAG-Account-Name: sean↵
↵
~~~~

#### Press Tag

The client now has a token which identifies the client with the user
account on the server. Subsequent tag requests are made as POSTs to
`/tag` with this token sent in the request headers, so that they can be
stored against the user's account.

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
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
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
X-RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 1032↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Feedback</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T13:59:50+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5967db0e-dc63-428d-a075-90cf316ded5d</id>
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

The client can again request a list of tags, this time using the new
authentication token. The server has migrated the tags created while the
client was unpaired to the user's account, so all three tags created
above are returned in the Atom feed.

##### Request

~~~~ {.example}
GET /tags HTTP/1.1↵
X-RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
Host: radiotag.bbc.co.uk↵
↵
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Fri, 21 Oct 2011 12:59:50 GMT↵
Status: 200 OK↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: d7975fbd-343a-474f-9dc4-05752c83cea1↵
X-RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 2268↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Tag List</title>
  <link href="http://radiotag.bbc.co.uk/tags"/>
  <link href="http://radiotag.bbc.co.uk/tags" rel="self"/>
  <updated>2011-10-21T13:59:50+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:93beb9c2-0b8d-49ad-a813-c1e6120f63b9</id>
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

### Anonymous to paired

This section shows the HTTP traces of transactions between a RadioTag
client (e.g. a radio) and a RadioTag service. It covers the scenario
where the RadioTag service permits *anonymous* tagging upgradeable to
*paired* tagging, i.e. it provides a response to an unauthorized client
but does not store tags until the client has been paired with a user
account.

Here we deal only with the differences between this scenario and the
unpaired-to-paired scenario above. Please refer to that document for
more information.

#### Press Tag

The user presses the `Tag` button. Note that the request is exactly the
same as in the unpaired case above.

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319202059
~~~~

##### Response

The response is a `200 OK` rather than a `201 Created`. The client
should remember this result for later as it indicates that the client
should resubmit the tag request after registration.

Note that just like the unpaired case, the response contains a
`can_register` grant. The client can use this to provide the choice to
accept the result or to register the client.

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Fri, 21 Oct 2011 13:00:59 GMT↵
Status: 200 OK↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 973↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>The Archers</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T14:00:59+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:3bfaa9dd-11ed-45f9-8f3c-6587db086b04</id>
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

At this point, the client can forget the stored `200 OK` result code.

#### Press Tags

##### Request

~~~~ {.example}
GET /tags HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
Host: radiotag.bbc.co.uk↵
↵
~~~~

##### Response

As this service does not provide unpaired tagging, there are no tags
stored on the server.

~~~~ {.example}
HTTP/1.1 401 Unauthorized↵
Date: Fri, 21 Oct 2011 13:00:59 GMT↵
Status: 401 Unauthorized↵
X-RadioTAG-Service-Provider: BBC↵
Content-Type: text/html;charset=utf-8↵
Content-Length: 12↵
↵
Unauthorized
~~~~

#### Press Tag

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
Content-Length: 43↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
station=0.c224.ce15.ce1.dab&time=1319202059
~~~~

##### Response

Again, the client should remember that the return code for this `/tag`
request is 200.

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Fri, 21 Oct 2011 13:01:00 GMT↵
Status: 200 OK↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 973↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>The Archers</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T14:00:59+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:8ea43558-70c2-4a4a-aeb9-8ffeee700898</id>
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
grant_scope=can_register&grant_token=ddc7f510-9353-45ad-9202-746ffe3b663a
~~~~

##### Response

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 13:01:00 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Registration-Key: 4fa9ed43↵
X-RadioTAG-Registration-Url: http://radiotag.bbc.co.uk/↵
↵
~~~~

#### Register with the web front end to get a PIN

Registering with a web front end is outside the scope of the RadioTAG
specification. See the [section above](#sec-5-1-7) for one possible
implementation.

#### Enter PIN

##### Request

Note that unlike the unpaired case, there is no auth token to send.

~~~~ {.example}
POST /register HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
Content-Length: 34↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
registration_key=4fa9ed43&pin=9666
~~~~

##### Response

The client has now completed the pairing process so receives an
`X-RadioTAG-Auth-Token` header which it should include as a request
header in all future requests.

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Fri, 21 Oct 2011 13:01:00 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: 0f73d1b8-e6b5-451e-9ecf-1a3c33c76415↵
X-RadioTAG-Account-Name: sean↵
↵
~~~~

##### Request

The client should have stored the result of the previous request to
`/tag`. As it was a `200 OK` rather than `201 Created`, the client knows
it should resubmit the tag request, this time including the newly
acquired `X-RadioTAG-Auth-Token` in the request header:

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: 0f73d1b8-e6b5-451e-9ecf-1a3c33c76415↵
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
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: 0f73d1b8-e6b5-451e-9ecf-1a3c33c76415↵
X-RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 973↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>The Archers</title>
  <link href="http://radiotag.bbc.co.uk"/>
  <link href="http://radiotag.bbc.co.uk" rel="self"/>
  <updated>2011-10-21T14:01:00+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:fcbb6008-aa54-45b4-91c9-78ec0655f9d7</id>
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

## API

### Some general points

Requests pass information in a combination of HTTP headers and form
encoded POST parameters.

Responses pass data back in a combination of HTTP headers and XML.

UTF-8 is the only supported character set.

### Common response headers

--------------------------------------------------------------------------------
Name                         Value
---------------------------  ---------------------------------------------------
X-RadioTAG-Service-Provider  The display name of the tag service provider

X-RadioTAG-Account-Name      The display name of the associated paired account

X-RadioTAG-Auth-Token        The authorization token for an unpaired or paired
                             client

--------------------------------------------------------------------------------

The `X-RadioTAG-Service-Provider` header should be returned in all
responses.

The `X-RadioTAG-Account-Name` should be returned in all responses to
requests made by a paired client.

The `X-RadioTAG-Auth-Token` header is returned when the client has been
granted authorization. It also enables the tag service to issue a new
token to replace an old one - see the next section.

### Updating tokens

The tag service can change the `X-RadioTAG-Auth-Token` in response to
any authorized request (i.e. one which contains a valid Auth Token). The
client should *always* use the last received Auth Token and update any
stored value from that. This provides a way for a tag service to expire
tokens.

We recommend that tag service implementations allow a period of grace in
which an expired token can co-exist with its replacement. This will
address the case where the token was updated but the response was not
received by the client.

### POST /tag

#### Request

##### Headers

--------------------------------------------------------------
Name                   Value
---------------------  ---------------------------------------
X-RadioTAG-Auth-Token  Empty OR unpaired token OR paired token

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

401               Unauthorized  Anonymous tagging is not supported and the token
                                is blank or does not
                                match either an unpaired or paired account

--------------------------------------------------------------------------------

##### Headers

-------------------------------------------------------------------------------
Name                         Value
---------------------------  --------------------------------------------------
X-RadioTAG-Service-Provider  The display name of the tag service provider

X-RadioTAG-Auth-Token        The token to use from now on.

X-RadioTAG-Account-Name      The display name of the associated paired account.

X-RadioTAG-Grant-Scope       "unpaired" or "can\_register". See Grants.

X-RadioTAG-Grant-Token       The token to use when exercising the grant.

-------------------------------------------------------------------------------

A grant header is *not* returned in the following cases:

- the server supports only anonymous tags
- the client is already using a paired token
- the client is using an unpaired token and the tag service doesn't
  support pairing

##### Body

On a successful request (status 200 or 201), the body contains an Atom
feed containing a single entry representing the tag. See [Data
formats](#sec-7) below.

On an unsuccessful request, the body may be blank or may contain a short
explanation of why the request failed.

#### Example 1 - `POST /tag` with no token

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
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
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: unpaired↵
X-RadioTAG-Grant-Token: b86bfdfb-5ff5-4cc7-8c61-daaa4804f188↵
Content-Type: text/html;charset=utf-8↵
Content-Length: 18↵
↵
Must request token
~~~~

#### Example 2 - `POST /tag` with a valid unpaired token

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: be222d22-4cef-439e-a77c-c867441dcb33↵
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
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 957↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>PM</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-02T17:03:24+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:fb669d2c-63b3-420b-9dd6-131f5d58e68a</id>
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

Note that the response header contains the `X-RadioTAG-Grant-Scope`
`can_register`. This will be present only if the service supports paired
tagging.

#### Example 3 - `POST /tag` with a valid paired token

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: b48bf7ed-14a6-429e-b5c8-35f7a4c094b7↵
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
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: b48bf7ed-14a6-429e-b5c8-35f7a4c094b7↵
X-RadioTAG-Account-Name: sean↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 958↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>PM</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-02T17:22:09+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:8facc0c0-ce13-4349-8664-dc71d55c6c97</id>
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
contain the paired account name.

#### Example 4 - `POST /tag` against a service that does not provide unpaired tagging

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
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
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 992↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Meet David Sedaris</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-01T11:38:38+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
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

#### Example 5 - `POST /tag` against a service that provides only anonymous tagging

##### Request

~~~~ {.example}
POST /tag HTTP/1.1↵
X-RadioTAG-Auth-Token: ↵
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
X-RadioTAG-Service-Provider: BBC↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 992↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Meet David Sedaris</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-01T11:38:38+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
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
grant\_scope  The value of the X-RadioTAG-Grant-Scope provided in the previous
              request

grant\_token  The value of the X-RadioTAG-Grant-Token provided in the previous
              request

--------------------------------------------------------------------------------

For more information, see [Grants](#Grants).

##### Example

~~~~ {.example}
POST /token HTTP/1.1↵
Content-Length: 69↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=unpaired&grant_token=b86bfdfb-5ff5-4cc7-8c61-daaa4804f188
~~~~

#### Response

##### Status

--------------------------------------------------------------------------------
HTTP Status Code  HTTP Status   Explanation
----------------  ------------  ------------------------------------------------
204               No Content    The token was successfully created

401               Unauthorized  The grant is missing or invalid

403               Forbidden     The grant is valid but the client is not allowed
                                to make this request

--------------------------------------------------------------------------------

##### Headers

-------------------------------------------------------------------------------
Name                         Value
---------------------------  --------------------------------------------------
X-RadioTAG-Service-Provider  The display name of the tag service provider

X-RadioTAG-Auth-Token        The newly issued token to use for future requests.

-------------------------------------------------------------------------------

##### Body

The `/token` endpoint should not return any content (as denoted by the
204 status code).

##### Example

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Tue, 02 Aug 2011 16:22:08 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: cf7ce9dc-7762-4b4c-970a-d194c5aa03ed↵
↵
~~~~

### GET /tags

#### Request

##### Headers

-----------------------------------------------------
Name                   Value
---------------------  ------------------------------
X-RadioTAG-Auth-Token  Unpaired token OR paired token

-----------------------------------------------------

##### Parameters

None.

##### Example

~~~~ {.example}
GET /tags HTTP/1.1↵
X-RadioTAG-Auth-Token: cf7ce9dc-7762-4b4c-970a-d194c5aa03ed↵
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
X-RadioTAG-Account-Name      The display name of the associated paired account
                             (if applicable)

X-RadioTAG-Service-Provider  The display name of the tag service provider

X-RadioTAG-Grant-Scope       If the service provides pairing, this will have the
                             value
                             `can_register`. See [Grants](#Grants)

X-RadioTAG-Grant-Token       The token to use when exercising the `can_register`
                             grant

--------------------------------------------------------------------------------

##### Body

##### Example

~~~~ {.example}
HTTP/1.1 200 OK↵
Date: Tue, 02 Aug 2011 16:22:08 GMT↵
Status: 200 OK↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Grant-Scope: can_register↵
X-RadioTAG-Grant-Token: ddc7f510-9353-45ad-9202-746ffe3b663a↵
Content-Type: application/xml;charset=utf-8↵
Content-Length: 974↵
↵
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Tag List</title>
  <link href="http://radiotag.example.com/tags"/>
  <link href="http://radiotag.example.com/tags" rel="self"/>
  <updated>2011-08-02T17:22:08+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:6a041e97-65bb-4b12-82da-c1b373731905</id>
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
</feed>
~~~~

### POST /registration\_key

#### Request

##### Headers

-------------------------------------------------------------
Name                   Value
---------------------  --------------------------------------
X-RadioTAG-Auth-Token  Either blank or a valid unpaired token

-------------------------------------------------------------

##### Parameters

--------------------------------------------------------------------
Name          Value
------------  ------------------------------------------------------
grant\_scope  Must be the value `can_register`

grant\_token  Must be the grant token issued in the previous request

--------------------------------------------------------------------

##### Example

~~~~ {.example}
POST /registration_key HTTP/1.1↵
Content-Length: 73↵
Content-Type: application/x-www-form-urlencoded↵
Host: radiotag.bbc.co.uk↵
↵
grant_scope=can_register&grant_token=ddc7f510-9353-45ad-9202-746ffe3b663a
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
X-RadioTAG-Service-Provider  The display name of the tag service provider

X-RadioTAG-Registration-Key  The registration key to use when pairing the
                             device.

X-RadioTAG-Registration-Url  The url to visit to register the device.

--------------------------------------------------------------------------------

##### Body

This response contains no body.

##### Example

~~~~ {.example}
HTTP/1.1 204 No Content↵
Date: Tue, 02 Aug 2011 16:22:09 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Registration-Key: 2b188492↵
X-RadioTAG-Registration-Url: http://radiotag.example.com/↵
↵
~~~~

### POST /register

#### Request

##### Headers

-----------------------------------------------------
Name                   Value
---------------------  ------------------------------
X-RadioTAG-Auth-Token  Unpaired token OR paired token

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
X-RadioTAG-Auth-Token: cf7ce9dc-7762-4b4c-970a-d194c5aa03ed↵
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
204               No Content   The registration has succeeded and the device has
                               been paired to the
                               associated account

--------------------------------------------------------------------------------

##### Headers

------------------------------------------------------------------------------
Name                         Value
---------------------------  -------------------------------------------------
X-RadioTAG-Service-Provider  The display name of the tag service provider

X-RadioTAG-Auth-Token        The token to use for future requests

X-RadioTAG-Account-Name      The display name of the associated paired account

------------------------------------------------------------------------------

##### Body

There is no body returned in this response.

##### Example

~~~~ {.example}
HTTP/1.1 201 Created↵
Date: Tue, 02 Aug 2011 16:22:09 GMT↵
Status: 204 No Content↵
X-RadioTAG-Service-Provider: BBC↵
X-RadioTAG-Auth-Token: b48bf7ed-14a6-429e-b5c8-35f7a4c094b7↵
X-RadioTAG-Account-Name: sean↵
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
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Meet David Sedaris</title>
  <link href="http://radiotag.example.com"/>
  <link href="http://radiotag.example.com" rel="self"/>
  <updated>2011-08-01T11:38:38+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:5001c814-7a28-42a4-b35a-eef17abc7249</id>
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
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:radiotag="http://radiodns.org/2011/radiotag">
  <title>Tag List</title>
  <link href="http://radiotag.example.com/tags"/>
  <link href="http://radiotag.example.com/tags" rel="self"/>
  <updated>2011-08-02T17:22:09+01:00</updated>
  <author>
    <name>BBC</name>
  </author>
  <id>urn:uuid:bf3e7d30-ccb8-4b45-b438-c790fb2ec5f7</id>
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
X-RadioTAG-Account-Name      48

X-RadioTAG-Auth-Token        48

X-RadioTAG-Grant-Scope       16

X-RadioTAG-Grant-Token       48

X-RadioTAG-Registration-Key  10

X-RadioTAG-Registration-Url  128

X-RadioTAG-Service-Provider  16

-----------------------------------------------
