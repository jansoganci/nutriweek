import { Router, type IRouter } from "express";

const router: IRouter = Router();

const USDA_BASE = "https://api.nal.usda.gov/fdc/v1";

router.get("/foods/search", async (req, res) => {
  const { query, pageSize = "20" } = req.query;

  if (!query || typeof query !== "string" || !query.trim()) {
    res.status(400).json({ error: "query is required" });
    return;
  }

  const apiKey = process.env.USDA_API_KEY ?? "DEMO_KEY";
  const url =
    `${USDA_BASE}/foods/search` +
    `?query=${encodeURIComponent(query.trim())}` +
    `&api_key=${apiKey}` +
    `&pageSize=${pageSize}` +
    `&dataType=Foundation,SR%20Legacy`;

  try {
    const upstream = await fetch(url);
    if (!upstream.ok) {
      req.log.warn({ status: upstream.status }, "USDA upstream error");
      res.status(upstream.status).json({ error: "USDA API error", foods: [] });
      return;
    }
    const data = await upstream.json();
    res.json(data);
  } catch (err) {
    req.log.error({ err }, "USDA proxy fetch failed");
    res.status(502).json({ error: "Failed to reach USDA API", foods: [] });
  }
});

export default router;
