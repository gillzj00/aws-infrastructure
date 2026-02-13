/**
 * DynamoDB DocumentClient wrapper for the guestbook table.
 *
 * Uses @aws-sdk/lib-dynamodb which automatically marshals/unmarshals
 * DynamoDB attribute types (e.g. { S: "hello" } ↔ "hello"), so we
 * work with plain JavaScript objects instead of DynamoDB's type notation.
 */
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  DeleteCommand,
  ScanCommand,
} from "@aws-sdk/lib-dynamodb";

const client = DynamoDBDocumentClient.from(new DynamoDBClient());
const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME;

/**
 * Write a new guestbook entry.
 */
export async function putEntry(entry) {
  await client.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: entry,
    })
  );
}

/**
 * Fetch a single entry by its primary key.
 * Returns the entry object or null if not found.
 */
export async function getEntry(entryId) {
  const { Item } = await client.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { entryId },
    })
  );
  return Item || null;
}

/**
 * Delete a guestbook entry by its primary key.
 */
export async function deleteEntry(entryId) {
  await client.send(
    new DeleteCommand({
      TableName: TABLE_NAME,
      Key: { entryId },
    })
  );
}

/**
 * Fetch all guestbook entries, newest first.
 *
 * Scan is fine here because:
 * 1. This is a personal guestbook — we'll have tens/hundreds of entries, not millions
 * 2. DynamoDB Scan reads every item, but at this scale it's <1 RCU and <10ms
 * 3. If it ever grows large, we'd add a GSI with a timestamp sort key
 */
export async function listEntries() {
  const { Items = [] } = await client.send(
    new ScanCommand({ TableName: TABLE_NAME })
  );

  // Sort client-side by createdAt descending (newest first)
  return Items.sort((a, b) => (b.createdAt || "").localeCompare(a.createdAt || ""));
}
