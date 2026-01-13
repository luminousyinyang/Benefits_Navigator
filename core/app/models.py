from pydantic import BaseModel, EmailStr

class UserSignup(BaseModel):
    email: EmailStr
    password: str
    first_name: str
    last_name: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    id_token: str
    local_id: str
    email: str
    refresh_token: str | None = None
    expires_in: str | int | None = None

class UserProfile(BaseModel):
    uid: str
    email: str
    first_name: str
    last_name: str
    onboarded: bool = False
    total_cashback: float = 0.0
    top_retailer: str = "Must do more shopping!"

class Benefit(BaseModel):
    category: str
    title: str
    description: str
    details: str | None = None

class Card(BaseModel):
    id: str | None = None
    name: str
    brand: str
    benefits: list[Benefit]

class SignOnBonus(BaseModel):
    bonus_value: float
    bonus_type: str # "Points" or "Dollars"
    current_spend: float = 0.0
    target_spend: float = 0.0 # Added for progress bar
    end_date: str # Using string for easier JSON handling (ISO format YYYY-MM-DD)
    last_updated: str | None = None # ISO format YYYY-MM-DD, tracks when bonus was last updated manually or via statement

class UserCard(BaseModel):
    card_id: str
    name: str
    brand: str
    benefits: list[Benefit] | None = None
    sign_on_bonus: SignOnBonus | None = None

class RecommendationRequest(BaseModel):
    store_name: str
    prioritize_warranty: bool
    user_cards: list[UserCard]

class RecommendationResponse(BaseModel):
    best_card_id: str
    reasoning: list[str]
    estimated_return: str
    runner_up_id: str | None = None
    runner_up_reasoning: list[str] | None = None
    runner_up_return: str | None = None
