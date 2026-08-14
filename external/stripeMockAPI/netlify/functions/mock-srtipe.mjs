const mockData = {
  200: {
    id: "ch_mock_123456",
    object: "charge",
    amount: 2500,
    currency: "usd",
    status: "succeeded",
    paid: true,
    customer: "cus_mock_123456",
    description: "Mock Stripe payment"
  },
  201: {
    id: "cus_mock_123456",
    object: "customer",
    email: "mock.customer@example.com",
    name: "Mock Customer",
    created: 1723632000
  },
  400: {
    error: {
      type: "invalid_request_error",
      code: "parameter_missing",
      message: "Mock Stripe: required parameter is missing."
    }
  },
  401: {
    error: {
      type: "authentication_error",
      code: "invalid_api_key",
      message: "Mock Stripe: authentication failed."
    }
  },
  403: {
    error: {
      type: "permission_error",
      message: "Mock Stripe: permission denied."
    }
  },
  404: {
    error: {
      type: "invalid_request_error",
      message: "Mock Stripe: resource not found."
    }
  },
  429: {
    error: {
      type: "rate_limit_error",
      message: "Mock Stripe: too many requests.",
      retry_after: 60
    }
  },
  500: {
    error: {
      type: "api_error",
      message: "Mock Stripe: internal server error."
    }
  },
  502: {
    error: {
      type: "api_error",
      message: "Mock Stripe: bad gateway."
    }
  },
  503: {
    error: {
      type: "api_error",
      message: "Mock Stripe: service unavailable."
    }
  },
  504: {
    error: {
      type: "api_error",
      message: "Mock Stripe: gateway timeout."
    }
  }
};

export default async (req) => {
  const url = new URL(req.url);

  const requestedCode = Number(url.searchParams.get("code") || "200");

  if (!Number.isInteger(requestedCode) || requestedCode < 100 || requestedCode > 599) {
    return Response.json(
      {
        error: {
          type: "invalid_request_error",
          message: "code must be a valid HTTP status code."
        }
      },
      { status: 400 }
    );
  }

  let responseData = mockData[requestedCode];

  if (!responseData) {
    responseData = {
      id: "mock_response_123456",
      object: "mock_response",
      status: requestedCode,
      message: `Mock Stripe response for HTTP ${requestedCode}.`
    };
  }

  return Response.json(
    {
      mock: true,
      requested_status_code: requestedCode,
      data: responseData
    },
    {
      status: requestedCode,
      headers: {
        "Content-Type": "application/json",
        "X-Mock-Stripe": "true"
      }
    }
  );
};

export const config = {
  path: "/api/mock-stripe"
};