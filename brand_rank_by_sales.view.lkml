view: brand_rank_by_sales {
  derived_table: {
    sql:
      SELECT
         products.brand  AS "brand"
        ,COALESCE(SUM(order_items.sale_price ), 0) AS "total_revenue"
        ,RANK() OVER (ORDER BY COALESCE(SUM(order_items.sale_price ), 0) DESC) AS "RNK"
        ,PERCENT_RANK () OVER (ORDER BY COALESCE(SUM(order_items.sale_price ), 0)) AS "percent_rank"
      FROM
                public.order_items  AS order_items
      LEFT JOIN public.orders  AS orders ON orders.id = order_items.order_id
      LEFT JOIN public.inventory_items  AS inventory_items ON order_items.inventory_item_id = inventory_items.id
      LEFT JOIN public.products  AS products ON inventory_items.product_id = products.id
      WHERE
        1=1
        AND {% condition orders.created_date %} orders.created_at {% endcondition %}
        AND {% condition orders.traffic_source %} orders.traffic_source {% endcondition %}
      GROUP BY 1
      ORDER BY 2 DESC
       ;;
  }

  dimension: brand {
    hidden: yes
    primary_key: yes
    type: string
    sql: ${TABLE}.brand ;;
  }

  filter: other_bucket_threshold {
    type: number
  }

  dimension: percent_rank {
    type: number
    value_format_name: percent_2
    sql: ${TABLE}.percent_rank ;;
  }

  dimension: percentile_tiers {
    type: tier
    tiers: [0.25,0.5,0.75,0.9,0.95]
    sql: ${percent_rank} ;;
  }

  dimension: ranked_brand {
    type: string
    sql:
        CASE
            WHEN ${rnk} < 10 THEN '0'|| ${rnk} || ') ' || ${brand}
            ELSE ${rnk} || ') ' || ${brand}
        END
    ;;
  }

  dimension: ranked_brand_with_tail {
    type: string
    sql:
          CASE
            WHEN {% condition other_bucket_threshold %} ${rnk} {% endcondition %} THEN ${ranked_brand}
            ELSE  'x) Other'
          END
      ;;
  }


  dimension: total_revenue {
    hidden: yes
    type: number
    sql: ${TABLE}.total_revenue ;;
  }

  dimension: rnk {
    type: number
    sql: ${TABLE}.rnk ;;
  }

  set: detail {
    fields: [brand, total_revenue, rnk]
  }
}
