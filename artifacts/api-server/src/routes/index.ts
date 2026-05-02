import { Router, type IRouter } from "express";
import healthRouter from "./health";
import foodsRouter from "./foods";

const router: IRouter = Router();

router.use(healthRouter);
router.use(foodsRouter);

export default router;
