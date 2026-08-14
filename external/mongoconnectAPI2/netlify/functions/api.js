const { MongoClient } = require("mongodb");

let clientPromise;

function getMongoClient() {
  if (!clientPromise) {
    const client = new MongoClient(process.env.MONGODB_URI);
    clientPromise = client.connect();
  }

  return clientPromise;
}

exports.handler = async (event) => {
  // Only POST
  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        success: false,
        error: "Only POST requests are allowed"
      })
    };
  }

  // Authentication
  const clientId = event.headers["x-client-id"];
  const clientSecret = event.headers["x-client-secret"];

  if (
    clientId !== process.env.CLIENT_ID ||
    clientSecret !== process.env.CLIENT_SECRET
  ) {
    return {
      statusCode: 401,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        success: false,
        error: "Unauthorized"
      })
    };
  }

  try {
    // Parse incoming JSON
    const data = JSON.parse(event.body || "{}");

    // Connect to MongoDB
    const client = await getMongoClient();

    const collection = client
      .db("custDB")
      .collection("customer_onbaording");

    // Store timestamp + received JSON
    const document = {
      receivedAt: new Date(),
      data: data
    };

    const result = await collection.insertOne(document);

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        success: true,
        id: result.insertedId.toString(),
        receivedAt: document.receivedAt
      })
    };

  } catch (error) {
    console.error("API Error:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
  }
};