---
title: Identifying Ideal API Identifers
subtitle: What Makes GUIDs Good?
date: 2023-05-25 09:00:00 -0500

---

## Motivation

In my time as an engineer I have seen all of the following used in identifying 
API resources:
1. Integers, usually representing a sequential row ID in a database. Example: 
`123`.
2. Timestamps (yes, really). Example: `1684280000`.
2. Globally unique identifiers, also known as GUIDs or UUIDv4. Example: 
`289615c5-976a-41e5-ad67-c56bbd24b5df` 
3. Short GUIDs. Example: `9EcYJzNXNXp82F8mvFX7S7`. 
5. Prefixed GUIDs. Example: `acct_9EcYJzNXNXp82F8mvFX7S7`.


Let's say we're building a new API endpoint that fetches a list of `orders` 
for a given `customer_id`. What is the best 
API identifier to use for `customer_id`? Over the years I have observed 
developers overlooking key tradeoffs of these 
different options, compromising the security of the systems they maintain, and 
creating technical debt that will haunt 
their team for years. 

*In general, a GUID will offer the best compromise in terms of security, 
debugging, and user 
experience.* But let's break down each option, and use practical examples to 
explore their nuances.

## What problems do we need to solve?

### 1. URL safety

Our identifier must not contain any characters that cannot be encoded properly 
into a URL. So any old string won't do. For example, `\` in a URL would get rejected by `cURL` or 
another HTTP client because it is disallowed by the IETF standard. 

**All of our options meet this standard, so this rules out none of the above.**

### 2. Collision free

Collisions can violate our database schema and make it more likely that we 
will accidentally confuse two resources, opening up the possibility of sharing 
one customer's data with another customer. 

For example, let's say we have two database tables for customers: `customers` 
and `customers_legacy`, each having a few thousand rows. The API identifier is 
the integer row ID of the table. If we use a row id as the API identifier for 
both of these resources, and we accidentally introduce a bug that queries the 
wrong table in the wrong context, it's possible we will leak the contact 
information of one 
customer to a different customer. 

A related problem is unique constraints on database id's. If we use a 
timestamp as the API identifier on a resource, and we create two of those 
resources around the same time, there's a good possibility both resources will 
have the same identifier. When we go to insert them into the database, we will 
have a duplicate key error. Similarly, if we're merging two database shards, 
we won't have to worry about key collisions.


**This rules out integer row ids and timestamps.**

### 3. Non-sequential

For the `orders` table let's say we use a standard integer row ID. This would 
be a sequential, monotonically incrementing number. Let's also say we have a 
new endpoint that allows customers to view a particular order, but we forgot 
to check if the customer has access to that order before returning that data. 
If we use the row ID as our API identifier, a hacker can easily scan through 
all of our orders. 

In 2015, security researchers were able to remotely take over a Jeep by 
guessing the password. That password was based on the time at which the Jeep's 
computer was first turned on. Identifiers are not passwords, but the same 
security principles apply here. 

Finally, there's what's known as the German tank problem - if we expose how 
many widgets are in our system, and how quickly the number of widgets 
increases over time, that can offer valuable information to competitors. 
Fundamentally, we're leaking information that the client shouldn't need. 

**Again, this rules out integer row ids and timestamps.**

### 4. Presentation

In documentation and in our UI, such as in a URL, we want identifiers that 
make sense and don't take up too much room.

Sometimes I have used GUIDs in a URL, like 
`api.test/orders/289615c5-976a-41e5-ad67-c56bbd24b5df`. This makes the URL 
harder to read and work with for users. Compare that to the equivalent short 
GUID implementation: `api.test/orders/9EcYJzNXNXp82F8mvFX7S7`.

**This might rule out "long" GUIDs. If possible, do some user testing to 
validate 
product needs before deciding between GUID or Short GUID.**

# Conclusions

- Use a GUID.
- If a GUID feels "too ugly", use a Short GUID.
- Never use row IDs or timestamps.

## Grains of Salt 🧂 and Extra Bits
- This advice comes from working at just two companies for four years. Mostly 
with Python. Your mileage may vary.
- If we could generate an infinite number of GUIDs, we would eventually 
encounter a collision. But with 122 bits of randomness, this should not be a 
concern for most, if not all, use cases. It's also possible to generate a 
nonstandard GUID with more bits. If we make our GUIDs sequential to avoid 
collisions, we're losing a major benefit of using them in the first place. 
- For certain use cases, such as a ticketing system, a plain old number is 
ideal for the user experience because it's easy to work with and remember. But 
I would argue that this is a frontend concern; we don't have to use this 
number as the underlying API identifier - just treat that number as any other 
attribute of our resource.
- In some cases, timestamps might be added to the identifier for easier 
sorting and database indexing. 
- Some public APIs, such as Stripe, include a prefix that allows us to 
disambiguate the 
meaning of a particular identifier. In theory, disambiguation is helpful if 
the identifier could come from different places, like an external integration. 
For example, `"id": "acct_9EcYJzNXNXp82F8mvFX7S7"` would be a Stripe account 
number. Keep it simple and do `"account_id": "9EcYJzNXNXp82F8mvFX7S7"`. While 
Stripe has had many good ideas, this is not one of them. Use reasonable names 
for keys and our API responses will read like prose! 
- Our GUID is only as good as the underlying random number generator. Without 
sufficient entropy, GUIDs will be predictable and prone to collisions.
- If we setup a web application firewall (WAF) with proper rate limiting and 
blocking, can control how many chances an attacker has to guess an identifier 
correctly.
- Validate UUIDs in your controllers and database schemas. They are not just strings! Ignore data integrity at your own peril...
- I am not advocating for UUIDs as your primary key.

## Sources & Further Reading:
- datatracker.ietf.org/doc/html/rfc3986
- datatracker.ietf.org/doc/html/rfc4122
- wikipedia.org/wiki/German_tank_problem
- littlemaninmyhead.wordpress.com/2015/11/22/cautionary-note-uuids-should-generally-not-be-used-for-authentication-tokens/
- stripe.com/docs/api/authentication
- tomharrisonjr.com/uuid-or-guid-as-primary-keys-be-careful-7b2aa3dcb439
- usa.kaspersky.com/blog/blackhat-jeep-cherokee-hack-explained/5749/
- uuidtools.com/uuid-versions-explained



Scratch
- surrogate vs natural keys