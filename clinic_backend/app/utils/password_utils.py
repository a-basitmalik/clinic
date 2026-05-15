import secrets
import string
from werkzeug.security import generate_password_hash, check_password_hash


def hash_password(password: str) -> str:
    return generate_password_hash(password, method="pbkdf2:sha256:600000", salt_length=16)


def verify_password(plain: str, hashed: str) -> bool:
    return check_password_hash(hashed, plain)


def generate_temp_password(length: int = 12) -> str:
    """Generate a cryptographically random temporary password."""
    alphabet = string.ascii_letters + string.digits + "!@#$%"
    while True:
        pwd = "".join(secrets.choice(alphabet) for _ in range(length))
        # Ensure at least one digit, one uppercase, one lowercase, one special
        if (
            any(c.isdigit() for c in pwd)
            and any(c.isupper() for c in pwd)
            and any(c.islower() for c in pwd)
            and any(c in "!@#$%" for c in pwd)
        ):
            return pwd
