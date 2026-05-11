import { errorResponse, jsonResponse } from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("BAD_REQUEST", "POST required", 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse("UNAUTHORIZED", "Missing Authorization header", 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  try {
    const jwt = authHeader.replace(/^Bearer\s+/i, "");

    const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        "apikey": serviceRoleKey,
        "Authorization": `Bearer ${jwt}`,
      },
    });

    if (!userResponse.ok) {
      return errorResponse("UNAUTHORIZED", "Invalid token", 401);
    }

    const userData = (await userResponse.json()) as { id?: string };
    const userId = userData.id;

    if (!userId) {
      return errorResponse("UNAUTHORIZED", "Could not identify user", 401);
    }

    const deleteResponse = await fetch(
      `${supabaseUrl}/auth/v1/admin/users/${userId}`,
      {
        method: "DELETE",
        headers: {
          "apikey": serviceRoleKey,
          "Authorization": `Bearer ${serviceRoleKey}`,
        },
      },
    );

    if (!deleteResponse.ok) {
      const errText = await deleteResponse.text();
      console.error("Delete account failed:", deleteResponse.status, errText);
      return errorResponse("INTERNAL", "Failed to delete account", 500);
    }

    return jsonResponse({ success: true });
  } catch (error) {
    console.error("Delete account error:", error);
    return errorResponse("INTERNAL", "Failed to delete account", 500);
  }
});
