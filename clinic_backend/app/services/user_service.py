from ..extensions import db
from ..models.user import User
from ..utils.password_utils import hash_password, generate_temp_password


class UserService:

    @staticmethod
    def email_exists(email: str) -> bool:
        return User.query.filter_by(email=email.lower().strip()).first() is not None

    @staticmethod
    def create_user(
        name: str,
        email: str,
        phone: str,
        role: str,
        clinic_id: int = None,
        doctor_id: int = None,
        plain_password: str = None,
        must_change_password: bool = True,
        status: str = "active",
    ):
        """
        Create a user and flush to DB (no commit — caller owns the transaction).
        Returns (User, plain_password).
        Raises ValueError if the email is already taken.
        """
        email = email.lower().strip()

        if UserService.email_exists(email):
            raise ValueError(f"Email '{email}' is already registered in the system.")

        if plain_password is None:
            plain_password = generate_temp_password()

        user = User(
            name=name.strip(),
            email=email,
            phone=(phone or "").strip() or None,
            password_hash=hash_password(plain_password),
            role=role,
            clinic_id=clinic_id,
            doctor_id=doctor_id,
            status=status,
            must_change_password=must_change_password,
        )
        db.session.add(user)
        db.session.flush()  # populate user.id; caller must commit
        return user, plain_password

    @staticmethod
    def change_password(user: User, new_password: str) -> None:
        user.password_hash = hash_password(new_password)
        user.must_change_password = False
        db.session.commit()

    @staticmethod
    def get_by_id(user_id: int) -> User:
        return User.query.get(user_id)

    @staticmethod
    def get_by_email(email: str) -> User:
        return User.query.filter_by(email=email.lower().strip()).first()

    @staticmethod
    def email_taken_by_other(email: str, user_id: int) -> bool:
        email = (email or "").lower().strip()
        if not email:
            return False
        return (
            User.query.filter(User.email == email, User.id != int(user_id))
            .first()
            is not None
        )

    @staticmethod
    def update_user(user: User, *, name=None, email=None, phone=None, status=None) -> User:
        """Update a user record (no password changes). Caller owns commit."""
        if name is not None:
            user.name = (name or "").strip() or user.name

        if email is not None:
            new_email = (email or "").lower().strip()
            if not new_email:
                raise ValueError("Email cannot be blank.")
            if UserService.email_taken_by_other(new_email, user.id):
                raise ValueError(f"Email '{new_email}' is already registered in the system.")
            user.email = new_email

        if phone is not None:
            user.phone = (phone or "").strip() or None

        if status is not None:
            if status not in ("active", "inactive", "pending"):
                raise ValueError("Invalid user status.")
            user.status = status

        db.session.flush()
        return user

    @staticmethod
    def deactivate_user(user: User) -> None:
        user.status = "inactive"
        db.session.flush()
