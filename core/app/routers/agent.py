from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from models import AgentStartRequest, AgentPublicState
import auth
from services.marathon_agent import MarathonAgent

router = APIRouter(
    prefix="/agent",
    tags=["agent"],
    responses={404: {"description": "Not found"}},
)

# Shared Dependency (Assuming main.py exposes it or we import from main logic, 
# but circular imports are bad. We should duplicate get_current_user extraction or move it to a shared dependency file.
# For now, I'll rely on `main.py` having it, but `agent.py` can't import `main`.
# So I need to implement `get_current_user` logic here or move `get_current_user` to `auth.py` or `dependencies.py`.
# Checking `auth.py`, it has `verify_id_token`.
# I will implement a local dependency here to avoid main import issues.
from fastapi.security import OAuth2PasswordBearer
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        decoded_token = auth.auth.verify_id_token(token, check_revoked=True)
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

@router.post("/start")
def start_agent(request: AgentStartRequest, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    """
    Initializes the CreditAgent with a goal and triggers the first run immediately.
    """
    uid = current_user['uid']
    print(f"Starting agent for {uid} with goal: {request.goal}")
    
    try:
        # 1. Set the goal in Public State
        public_ref = auth.db.collection('users').document(uid).collection('public_agent_state').document('main')
        public_ref.set({
            "target_goal": request.goal,
            "status": "thinking" # UI can show loading based on this
        }, merge=True)
        
        # 2. Trigger Agent Cycle in Background
        agent = MarathonAgent()
        background_tasks.add_task(agent.run_agent_cycle, uid)
        
        return {"status": "started", "message": "Agent is thinking..."}
        
    except Exception as e:
        print(f"Error starting agent: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/state", response_model=AgentPublicState | None)
def get_agent_state(current_user: dict = Depends(get_current_user)):
    """
    Fetches the public agent state for the user.
    """
    uid = current_user['uid']
    try:
        public_ref = auth.db.collection('users').document(uid).collection('public_agent_state').document('main')
        doc = public_ref.get()
        if doc.exists:
            return doc.to_dict()
        return None
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
