export const jsonHeaders = {
  "Content-Type": "application/json",
};

export function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: jsonHeaders,
  });
}

export function errorResponse(
  code:
    | "BAD_REQUEST"
    | "AI_TIMEOUT"
    | "AI_UNAVAILABLE"
    | "AI_SCHEMA_INVALID"
    | "AI_RATE_LIMITED"
    | "UPSTREAM_ERROR"
    | "UNAUTHORIZED"
    | "INTERNAL",
  message: string,
  status: number,
): Response {
  return jsonResponse({ error: code, message }, status);
}

