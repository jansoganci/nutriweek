import { errorResponse, jsonResponse } from "../_shared/http.ts";

const USDA_BASE = "https://api.nal.usda.gov/fdc/v1";

type USDAFoodNutrient = {
  nutrientId?: number;
  nutrientNumber?: string;
  value?: number;
};

type USDAFood = {
  fdcId: number;
  description: string;
  foodNutrients?: USDAFoodNutrient[];
};

function nutrientValue(nutrients: USDAFoodNutrient[] | undefined, id: number): number {
  const hit = (nutrients ?? []).find((n) => n.nutrientId === id || n.nutrientNumber === String(id));
  return Math.round((hit?.value ?? 0) * 10) / 10;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("BAD_REQUEST", "POST required", 405);
  }

  let payload: { query?: string; pageSize?: number };
  try {
    payload = await req.json();
  } catch {
    return errorResponse("BAD_REQUEST", "Invalid JSON body", 400);
  }

  const query = payload.query?.trim();
  const pageSize = Math.max(1, Math.min(payload.pageSize ?? 20, 50));
  if (!query) {
    return errorResponse("BAD_REQUEST", "query is required", 400);
  }

  const apiKey = Deno.env.get("USDA_API_KEY");
  if (!apiKey) {
    return errorResponse("UNAUTHORIZED", "Missing USDA_API_KEY secret", 500);
  }

  const url =
    `${USDA_BASE}/foods/search` +
    `?query=${encodeURIComponent(query)}` +
    `&api_key=${apiKey}` +
    `&pageSize=${pageSize}` +
    `&dataType=Foundation,SR%20Legacy`;

  try {
    const upstream = await fetch(url);
    if (!upstream.ok) {
      return errorResponse("UPSTREAM_ERROR", `USDA upstream status ${upstream.status}`, 502);
    }
    const data = (await upstream.json()) as { foods?: USDAFood[] };
    const foods = (data.foods ?? []).map((food) => ({
      fdcId: food.fdcId,
      description: food.description ?? "Unknown food",
      calories: nutrientValue(food.foodNutrients, 1008),
      protein: nutrientValue(food.foodNutrients, 1003),
      carbs: nutrientValue(food.foodNutrients, 1005),
      fat: nutrientValue(food.foodNutrients, 1004),
      servingSize: 100,
    }));
    return jsonResponse({ foods });
  } catch {
    return errorResponse("UPSTREAM_ERROR", "Failed to reach USDA API", 502);
  }
});

