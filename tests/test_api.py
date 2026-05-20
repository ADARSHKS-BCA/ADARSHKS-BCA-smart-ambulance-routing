import unittest
from app import app

class APITestCase(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        
    def test_verify_license_missing_image(self):
        # A simple test for the API
        response = self.app.post('/api/verify-license')
        self.assertEqual(response.status_code, 400)

if __name__ == '__main__':
    unittest.main()
