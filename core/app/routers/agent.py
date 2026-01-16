from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from models import AgentStartRequest, AgentPublicState, MilestoneUpdateRequest
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

@router.post("/milestone/{milestone_id}/update")
async def update_milestone(
    milestone_id: str,
    update_data: MilestoneUpdateRequest,
    current_user: dict = Depends(get_current_user)
):
    """Update progress, notes, or status of a specific milestone."""
    try:
        uid = current_user['uid']
        # Correct path matching get_agent_state
        public_ref = auth.db.collection('users').document(uid).collection('public_agent_state').document('main')
        public_doc = public_ref.get()
        
        if not public_doc.exists:
            raise HTTPException(status_code=404, detail="Agent state not found")
        
        data = public_doc.to_dict()
        state = AgentPublicState(**data)
        
        # Find the milestone
        milestone_index = next((i for i, m in enumerate(state.roadmap) if m.id == milestone_id), None)
        
        if milestone_index is None:
            raise HTTPException(status_code=404, detail="Milestone not found")
        
        # Apply updates
        milestone = state.roadmap[milestone_index]
        if update_data.status is not None:
            milestone.status = update_data.status
        if update_data.spending_current is not None:
            milestone.spending_current = update_data.spending_current
        if update_data.user_notes is not None:
            milestone.user_notes = update_data.user_notes
        if update_data.manual_completion is not None:
            milestone.manual_completion = update_data.manual_completion
            
        # If manually marked completed, ensure status reflects it
        if update_data.manual_completion and update_data.status is None:
             milestone.status = "completed"
             
        # Save back to Firestore
        state.roadmap[milestone_index] = milestone
        # Use .dict() or .model_dump() depending on Pydantic version (v1 vs v2). models.py seems to imply v1 or compatible.
        public_ref.set(state.dict(), merge=True)
        
        return {"status": "success", "milestone": milestone}
        
    except Exception as e:
        print(f"Error updating milestone: {e}")
        raise HTTPException(status_code=500, detail=str(e))
