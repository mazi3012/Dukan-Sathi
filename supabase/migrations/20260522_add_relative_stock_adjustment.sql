-- Create function to adjust product stock relatively (conflict-free)
CREATE OR REPLACE FUNCTION adjust_product_stock(p_id uuid, p_delta integer)
RETURNS void AS $$
BEGIN
  UPDATE products
  SET stock_quantity = stock_quantity + p_delta
  WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;
