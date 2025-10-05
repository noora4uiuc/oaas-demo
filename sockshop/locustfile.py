"""
Sock Shop Load Testing with Locust
Run: locust -f locustfile.py --host=http://localhost
Web UI: http://localhost:8089
"""

from locust import HttpUser, task, between, events
import random
import json

# Sample product IDs from Sock Shop
PRODUCTS = [
    '03fef6ac-1896-4ce8-bd69-b798f85c6e0b',
    '510a0d7e-8e83-4193-b483-e27e09ddc34d',
    '808a2de1-1aaa-4c25-a9b9-6612e8f29a38',
    '819e1fbf-8b7e-4f6d-811f-693534916a8b',
    'd3588630-ad8e-49df-bbd7-3167f7efb246',
    'a0a4f044-b040-410d-8ead-4de0446aec7e',
    '837ab141-399e-4c1f-9abc-bace40296bac',
]

# Sample user IDs
USERS = [
    '57a98d98e4b00679b4a830af',
    '57a98d98e4b00679b4a830b0',
    '57a98d98e4b00679b4a830b1',
]


class BrowserUser(HttpUser):
    """User who just browses without buying (40% of users)"""
    weight = 4
    wait_time = between(2, 5)

    @task(3)
    def browse_catalogue(self):
        """Browse the product catalogue"""
        with self.client.get("/catalogue", catch_response=True, name="Browse Catalogue") as response:
            if response.status_code == 200:
                try:
                    products = response.json()
                    if len(products) > 0:
                        response.success()
                    else:
                        response.failure("No products found")
                except:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Got status {response.status_code}")

    @task(2)
    def view_product(self):
        """View a specific product"""
        product_id = random.choice(PRODUCTS)
        with self.client.get(f"/catalogue/{product_id}", catch_response=True, name="View Product") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status {response.status_code}")

    @task(1)
    def view_homepage(self):
        """Visit the homepage"""
        self.client.get("/", name="Homepage")


class ShopperUser(HttpUser):
    """User who browses and adds to cart (50% of users)"""
    weight = 5
    wait_time = between(1, 3)

    def on_start(self):
        """Initialize user session"""
        self.user_id = random.choice(USERS)

    @task(3)
    def browse_and_view(self):
        """Browse catalogue and view products"""
        # Browse catalogue
        self.client.get("/catalogue", name="Browse Catalogue")
        
        # View a product
        product_id = random.choice(PRODUCTS)
        self.client.get(f"/catalogue/{product_id}", name="View Product")

    @task(2)
    def add_to_cart(self):
        """Add item to shopping cart"""
        product_id = random.choice(PRODUCTS)
        
        # View product first
        self.client.get(f"/catalogue/{product_id}", name="View Product Before Add")
        
        # Add to cart
        payload = {
            "id": product_id,
            "quantity": random.randint(1, 3)
        }
        
        with self.client.post(
            "/cart",
            json=payload,
            headers={'Content-Type': 'application/json'},
            catch_response=True,
            name="Add to Cart"
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Got status {response.status_code}")

    @task(1)
    def view_cart(self):
        """View shopping cart"""
        self.client.get("/basket.html", name="View Cart")


class PowerUser(HttpUser):
    """User who completes full checkout (10% of users)"""
    weight = 1
    wait_time = between(1, 2)

    def on_start(self):
        """Initialize user session"""
        self.user_id = random.choice(USERS)

    @task(5)
    def quick_browse_and_buy(self):
        """Quick browse, add to cart, attempt checkout"""
        # Quick catalogue check
        self.client.get("/catalogue", name="Quick Browse")
        
        # Add multiple items quickly
        items_to_add = random.randint(2, 4)
        for _ in range(items_to_add):
            product_id = random.choice(PRODUCTS)
            payload = {
                "id": product_id,
                "quantity": random.randint(1, 2)
            }
            self.client.post(
                "/cart",
                json=payload,
                headers={'Content-Type': 'application/json'},
                name="Quick Add to Cart"
            )
        
        # View cart
        self.client.get("/basket.html", name="View Cart Before Checkout")
        
        # Attempt checkout (generates traces through orders, shipping, payment)
        checkout_payload = {
            "customer": self.user_id,
            "address": "57a98d98e4b00679b4a830ad",
            "card": "57a98d98e4b00679b4a830ae",
            "items": f"http://localhost/carts/{self.user_id}/items"
        }
        
        with self.client.post(
            "/orders",
            json=checkout_payload,
            headers={'Content-Type': 'application/json'},
            catch_response=True,
            name="Checkout"
        ) as response:
            # Accept various response codes as checkout might fail for test data
            if response.status_code in [200, 201, 400, 500]:
                response.success()
            else:
                response.failure(f"Unexpected status {response.status_code}")


# Event handlers for custom metrics
@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    print("\n" + "="*60)
    print("🧦  SOCK SHOP LOAD TEST STARTING")
    print("="*60)
    print(f"Host: {environment.host}")
    print(f"Users will simulate: Browsers (40%), Shoppers (50%), Power Users (10%)")
    print("\n📊 Monitor in SigNoz: http://localhost:3301")
    print("="*60 + "\n")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    print("\n" + "="*60)
    print("✅  SOCK SHOP LOAD TEST COMPLETED")
    print("="*60)
    print("\n📊 View traces in SigNoz: http://localhost:3301")
    print("   • Navigate to 'Services' to see all microservices")
    print("   • Navigate to 'Traces' to see distributed traces")
    print("   • Look for traces from: carts, orders, shipping services")
    print("="*60 + "\n")

