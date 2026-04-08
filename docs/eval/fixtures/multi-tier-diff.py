# app/services/payment_service.py

import os
import requests

# 问题 1 [blocking/security]: 硬编码的 API key
STRIPE_API_KEY = "sk_live_4eC39HqLyjWDarjtT1zdp7dc"


# 问题 2 [advisory/simplicity]: 过度工程的 Factory，只有一个实现
class PaymentProcessorFactory:
    """工厂模式：根据类型创建支付处理器"""

    _registry = {}

    @classmethod
    def register(cls, processor_type):
        def decorator(processor_cls):
            cls._registry[processor_type] = processor_cls
            return processor_cls
        return decorator

    @classmethod
    def create(cls, processor_type, **kwargs):
        if processor_type not in cls._registry:
            raise ValueError(f"Unknown processor type: {processor_type}")
        return cls._registry[processor_type](**kwargs)


@PaymentProcessorFactory.register("stripe")
class StripeProcessor:
    def __init__(self, api_key=None):
        self.api_key = api_key or STRIPE_API_KEY

    def charge(self, amount, currency, customer_id):
        response = requests.post(
            "https://api.stripe.com/v1/charges",
            auth=(self.api_key, ""),
            data={
                "amount": amount,
                "currency": currency,
                "customer": customer_id,
            },
        )
        return response.json()


# 问题 3 [analytical/architecture]: Service 层直接访问 Repository 的私有方法
class OrderService:
    def __init__(self, order_repo, user_repo):
        self.order_repo = order_repo
        self.user_repo = user_repo

    def create_order(self, user_id, items):
        # 违反层级边界：直接访问 repo 的私有查询方法
        user_record = self.user_repo._fetch_raw_record(user_id)

        # 应该使用 user_repo.find(user_id)
        if not user_record:
            raise ValueError("User not found")

        # 使用唯一的 Factory 实现（YAGNI 信号）
        processor = PaymentProcessorFactory.create("stripe")
        total = sum(item["price"] * item["quantity"] for item in items)

        charge_result = processor.charge(
            amount=int(total * 100),
            currency="usd",
            customer_id=user_record["stripe_customer_id"],
        )

        if charge_result.get("status") != "succeeded":
            raise RuntimeError("Payment failed")

        return self.order_repo.create(
            user_id=user_id,
            items=items,
            total=total,
            payment_id=charge_result["id"],
        )
