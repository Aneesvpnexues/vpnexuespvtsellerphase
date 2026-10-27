do $$
declare
  seller_a uuid;
  buyer_a uuid;
  product_id_type text;
  order_id_type text;
  product_one text;
  product_two text;
  order_one text;
begin
  select id into seller_a from auth.users where email = 'seller.a@example.com';
  if seller_a is null then
    raise exception 'Create auth user seller.a@example.com before seeding';
  end if;

  select id into buyer_a from auth.users where email = 'buyer.a@example.com';
  if buyer_a is null then
    raise exception 'Create auth user buyer.a@example.com before seeding';
  end if;

  insert into public.seller_profiles (user_id, display_name, location, verified, seller_type)
  values (seller_a, 'Demo Seller', 'Salem', true, 'farmer')
  on conflict (user_id) do update
  set display_name = excluded.display_name,
      location = excluded.location,
      verified = excluded.verified,
      seller_type = excluded.seller_type,
      updated_at = now();

  select data_type into product_id_type
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products' and column_name = 'id';

  select data_type into order_id_type
  from information_schema.columns
  where table_schema = 'public' and table_name = 'orders' and column_name = 'id';

  select id::text into product_one
  from public.products
  where seller_id = seller_a and name = 'Demo Tomato'
  limit 1;

  if product_one is null then
    product_one := gen_random_uuid()::text;
    if product_id_type = 'uuid' then
      insert into public.products (
        id, seller_id, name, category, current_price, original_price,
        weight, quantity, status, image_url
      )
      values (
        product_one::uuid, seller_a, 'Demo Tomato', 'Vegetables', 40.50, 50.00,
        'kg', 5, 'active', 'https://example.com/demo-tomato.png'
      );
    else
      insert into public.products (
        id, seller_id, name, category, current_price, original_price,
        weight, quantity, status, image_url
      )
      values (
        product_one::text, seller_a, 'Demo Tomato', 'Vegetables', 40.50, 50.00,
        'kg', 5, 'active', 'https://example.com/demo-tomato.png'
      );
    end if;
  end if;

  select id::text into product_two
  from public.products
  where seller_id = seller_a and name = 'Demo Rice'
  limit 1;

  if product_two is null then
    product_two := gen_random_uuid()::text;
    if product_id_type = 'uuid' then
      insert into public.products (
        id, seller_id, name, category, current_price, original_price,
        weight, quantity, status, image_url
      )
      values (
        product_two::uuid, seller_a, 'Demo Rice', 'Grains', 75.00, 90.00,
        'kg', 20, 'active', 'https://example.com/demo-rice.png'
      );
    else
      insert into public.products (
        id, seller_id, name, category, current_price, original_price,
        weight, quantity, status, image_url
      )
      values (
        product_two::text, seller_a, 'Demo Rice', 'Grains', 75.00, 90.00,
        'kg', 20, 'active', 'https://example.com/demo-rice.png'
      );
    end if;
  end if;

  select id::text into order_one
  from public.orders
  where user_id::text = buyer_a::text and customer_name = 'Demo Buyer'
  limit 1;

  if order_one is null then
    order_one := gen_random_uuid()::text;
    if order_id_type = 'uuid' then
      insert into public.orders (
        id, status, total_amount, user_id, payment_status,
        customer_name, payment_method, delivery_fee, subtotal
      )
      values (
        order_one::uuid, 'placed', 250.00, buyer_a, 'pending',
        'Demo Buyer', 'cod', 0.00, 250.00
      );
    else
      insert into public.orders (
        id, status, total_amount, user_id, payment_status,
        customer_name, payment_method, delivery_fee, subtotal
      )
      values (
        order_one::text, 'placed', 250.00, buyer_a, 'pending',
        'Demo Buyer', 'cod', 0.00, 250.00
      );
    end if;

    execute format(
      'insert into public.order_items (order_id, product_id, quantity, name, current_price, image_url)
       values ($1::%s, $2::%s, $3, $4, $5, $6)',
      order_id_type, product_id_type
    )
    using order_one, product_one, 2, 'Demo Tomato', 40.50, 'https://example.com/demo-tomato.png';

    execute format(
      'insert into public.order_items (order_id, product_id, quantity, name, current_price, image_url)
       values ($1::%s, $2::%s, $3, $4, $5, $6)',
      order_id_type, product_id_type
    )
    using order_one, product_two, 1, 'Demo Rice', 75.00, 'https://example.com/demo-rice.png';
  end if;
end
$$;
