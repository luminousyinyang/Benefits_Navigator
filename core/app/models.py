from pydantic import BaseModel, EmailStr
from enum import Enum

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
    financial_details: str | None = None

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
    prioritize_category: str | None = None
    user_cards: list[UserCard]

class RecommendationResponse(BaseModel):
    best_card_id: str
    reasoning: list[str]
    estimated_return: str
    runner_up_id: str | None = None
    runner_up_reasoning: list[str] | None = None
    runner_up_return: str | None = None
    # Enhanced Fields
    corrected_store_name: str | None = None
    is_valid_store: bool = True

class ActionCenterCategory(str, Enum):
    CAR_RENTAL = "car_rental_insurance"
    AIRPORT = "airport_benefits"
    WARRANTY = "warranty_benefits"
    PRICE_PROTECTION = "price_protection"
    RETURNS = "guaranteed_returns"
    CELL_PHONE = "cell_phone_protection"

class ActionItem(BaseModel):
    id: str | None = None
    category: ActionCenterCategory
    card_id: str
    card_name: str
    retailer: str
    date: str # ISO Date
    total: float
    # Category Specifics (Optional)
    car_rented: str | None = None
    flight_info: str | None = None # Ticket/Flight numbers
    item_bought: str | None = None
    phone_bought: str | None = None
    
    # Help / LLM
    help_requested: bool = False
    gemini_instructions: str | None = None
    
    # Price Protection Specifics
    monitor_price: bool = False
    monitor_price: bool = False
    lowest_price_found: float | None = None
    lowest_price_url: str | None = None
    last_checked: str | None = None

class HelpRequest(BaseModel):
    user_notes: str

# CreditAgent Models

class AgentPrivateState(BaseModel):
    thought_signature: str
    last_run_date: str # ISO
    next_scheduled_action: str | None = None # ISO

class Milestone(BaseModel):
    id: str
    title: str
    description: str = ""
    status: str # "completed", "current", "locked"
    date: str | None = None
    icon: str = "star.fill" # SF Symbol name
    # New Fields for Phase 3
    spending_goal: float | None = None
    spending_current: float | None = None
    user_notes: str | None = None
    manual_completion: bool = False

class MilestoneUpdateRequest(BaseModel):
    status: str | None = None
    spending_current: float | None = None
    user_notes: str | None = None
    manual_completion: bool | None = None

class OptionalTask(BaseModel):
    id: str
    title: str
    description: str
    icon: str # SF Symbol
    impact: str # e.g. "Save ~$200/mo"
    category: str # "Savings", "Credit Health", "Lifestyle"
    status: str = "active" # "active", "completed", "dismissed"

class AgentPublicState(BaseModel):
    target_goal: str
    roadmap: list[Milestone] = []
    progress_percentage: int | None = 0
    next_action: str | None = "Analyzing..." # Kept for backward compatibility
    action_date: str | None = None # Kept for backward compatibility
    reasoning_summary: str | None = "Agent is starting..."
    status: str | None = None # "thinking", "idle", "error"
    error_message: str | None = None # New field for user-facing errors
    optional_tasks: list[OptionalTask] = [] # New Field

class AgentStartRequest(BaseModel):
    goal: str
