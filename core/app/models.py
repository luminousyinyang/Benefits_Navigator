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

class UserCard(BaseModel):
    card_id: str
    name: str
    brand: str
    # We might not need benefits for the list view, but helpful
    benefits: list[Benefit] | None = None

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
