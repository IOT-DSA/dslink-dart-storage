# Storage DSLink

A Key-Value Storage System for DSA.

## Concepts

If you want to think in terms of JSON, the storage system thinks in terms of a map of a string to a map a string and a value. Confused? Take a look:

```json
{
  "bucketA": {
    "keyA": "Hello World"
  },
  "bucketB": {
    "keyA": "Goodbye World"
  }
}
```

### Buckets

Buckets are like a table in SQL-like systems. Buckets contains entries, which you can see below.

### Entries

An entry is a mapping from a key to a value. The key is always a string. When you create an entry, you specify the type of the value for the key. This can be any of the DSA value types.

## Usage

```bash
pub get
dart bin/run.dart
```

To create a bucket, use the `Create Bucket` action on the link. To create an entry, use the `Create Entry` action on the bucket. To set the value of an entry, set the value of the entry node. To delete an entry, use the `Delete Entry` action on the entry. To delete a bucket, use the `Delete Bucket` action on the bucket.
