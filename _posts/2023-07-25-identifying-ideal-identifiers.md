--- 
title: Choosing API Identifers 
subtitle: Why GUIDs Should Be the Answer 99% of the Time.  
date: 2023-07-25 09:00:00 -0500

---

## Motivation

In my time as an engineer I have seen all of the following used in
identifying API resources: 1. Integers, usually representing a
sequential row ID in a database. Example: `123`.  2. Timestamps
(yes, really). Example: `1684280000`.  2. Globally unique
identifiers, also known as GUIDs or UUIDv4. Example:
`289615c5-976a-41e5-ad67-c56bbd24b5df` 3. Short GUIDs. Example:
`9EcYJzNXNXp82F8mvFX7S7`.  5. Prefixed GUIDs. Example:
`acct_9EcYJzNXNXp82F8mvFX7S7`.


Let's say we're building a new API endpoint that fetches a list of
`orders` for a given `customer_id`. What is the best API
identifier to use for `customer_id`? Over the years I have
observed developers overlooking key tradeoffs of these different
options, weakening the security of the systems they maintain and
creating technical debt that will haunt their team for years. 

*In general, a GUID will offer the best compromise in terms of
security, debugging, and user experience.* But let's break down
each option, and use practical examples to explore their nuances.

## What problems do we need to solve?

### 1. URL safety

Our identifier must not contain any characters that cannot be
encoded properly into a URL. So any old string won't do. For
example, `\` in a URL would get rejected by `cURL` or another HTTP
client because it is disallowed by the IETF standard. 

**All of our options meet this standard, so this rules out none of
the above.**

### 2. Collision free

Collisions can violate our database schema and make it more likely
that we will accidentally confuse two resources, opening up the
possibility of sharing one customer's data with another customer. 

For example, let's say we have two database tables for customers:
`customers` and `customers_legacy`, each having a few thousand
rows. The API identifier is the integer row ID of the table. If we
use a row id as the API identifier for both of these resources,
and we accidentally introduce a bug that queries the wrong table
in the wrong context, it's possible we will leak the contact
information of one customer to a different customer. 

A related problem is unique constraints on database id's. If we
use a timestamp as the API identifier on a resource, and we create
two of those resources around the same time, there's a good
possibility both resources will have the same identifier and the
database will throw an exception.


**This rules out integer row ids and timestamps.**

### 3. Non-sequential

For the `orders` table let's say we use a integer row ID. This
would be a sequential, monotonically increasing integer. Let's
also say we have a new endpoint that allows customers to view a
particular order, but we forgot to check if the customer has
access to that order before returning that data.  If we use the
row ID as our API identifier, a hacker can easily scan through all
of our orders. This is a common mistake in the real world. For
example, in 2017 it was discovered that Panera was leaking data on
millions of customers because it used sequential integers and weak
security.

Finally, there's what's known as the German tank problem - if we
expose how many widgets are in our system, and how quickly the
number of widgets increases over time, that can offer valuable
information to competitors.  Fundamentally, we're leaking
information that the client shouldn't need. 

**Again, this rules out integer row ids and timestamps.**

### 4. Presentation

In documentation and in our UI, such as in a URL, we want
identifiers that are legible and concise.

Sometimes I have used GUIDs in a URL, like
`api.test/orders/289615c5-976a-41e5-ad67-c56bbd24b5df`. Compare
that to the equivalent short GUID implementation:
`api.test/orders/9EcYJzNXNXp82F8mvFX7S7`. Short GUIDs use a wider
character set - note the mix of uppercase/lowercase letters - to
compress a traditional 36 character GUID into only 22 characters.
In theory, a more concise GUID creates less visual clutter and is
easier work with. In practice, I haven't seen a demand for this
from users. If you have a system that already stores GUIDs,
there's now an additional translation that needs to happen between
your database layer and your API layer. This slows down debugging
and adds complexity to our implementation.

In that same vein, id's with prefixes such as have become a
popular way to disambiguate the purpose of a particular key. In
theory, disambiguation is helpful if the identifier could come
from different places, like an external integration.  For example,
Stripe would use `person_9EcYJzNXNXp82F8mvFX7S7` to identify a
person in their API. This information feels redundant, because in
the context of working with APIs you already have other details
that make the purpose of the identifier obvious. 

The "Retrieve a person" endpoint returns this JSON blob:

``` 
{ 
   "id": "person_9EcYJzNXNXp82F8mvFX7S7", 
   ...  
} 
```

Or for another example, the endpoint URL
`api.stripe.com/v1/accounts/acct_1032D82eZvKYlo2C/persons/person_1NWrd12eZvKYlo2C6nQJNmr`

In both cases I already know we're dealing with a `Person`,
there's no additional signal to including the prefix. While Stripe
has had many good engineering ideas, I would contend that this may
not be not one of them.

Before experimenting with short GUIDs, prefixes, or other more
sophisticated approaches, do some user testing to validate product
needs before deciding whether the added complexity makes sense.

# Conclusions

- Use a GUID.
- If a GUID feels "too ugly", use a Short GUID.
- Never use row IDs or timestamps.

## Grains of Salt 🧂 and Extra Bits
- This advice comes from working at just two companies for four
  years. There could very well be nuances I have not yet 
  encountered! Your mileage may vary.
- If we could generate an infinite number of GUIDs, we would
  eventually encounter a collision. But with 122 bits of
randomness, this should not be a concern for most, if not all, use
cases. It's also possible to generate a nonstandard GUID with more
bits. If we make our GUIDs sequential to avoid collisions, we're
losing a major benefit of using them in the first place. 
- For certain use cases, such as a ticketing system, e.g. JIRA, a
  plain old number is ideal for the user experience because it's
easy to work with and remember. But I would argue that this is a
frontend concern; we don't have to use this number as the
underlying API identifier - just treat that number as any other
attribute of our resource.
- In some cases, timestamps might be added to the identifier for
  optimal sorting and database indexing. 
- A GUID is only as strong as the underlying psuedo random number
  generator. Without sufficient entropy, GUIDs will be predictable
and prone to collisions.
- If we setup a web application firewall (WAF) with proper rate
  limiting and blocking, can control how many chances an attacker
has to guess an identifier correctly.
- Validate UUIDs in your controllers before persisting them. They
  are not just strings! Ignore data integrity at your peril...

## Sources & Further Reading:
- datatracker.ietf.org/doc/html/rfc3986
- datatracker.ietf.org/doc/html/rfc4122
- krebsonsecurity.com/2018/04/panerabread-com-leaks-millions-of-customer-records/
- stripe.com/docs/api/authentication
- tomharrisonjr.com/uuid-or-guid-as-primary-keys-be-careful-7b2aa3dcb439
- usa.kaspersky.com/blog/blackhat-jeep-cherokee-hack-explained/5749/
- uuidtools.com/uuid-versions-explained
- wikipedia.org/wiki/German_tank_problem
- wikipedia.org/wiki/Natural_key
- wikipedia.org/wiki/Surrogate_key
