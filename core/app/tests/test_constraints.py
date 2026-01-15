import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import services.constraints as constraints
from datetime import datetime, timedelta

def test_check_5_24_status():
    print("Testing check_5_24_status...")
    
    # 1. Safe User (0 cards)
    assert constraints.check_5_24_status([]) == True
    print("✅ Empty history passed")

    # 2. Safe User (4 cards in last 24 months)
    now = datetime.now()
    history_safe = [{"date_opened": (now - timedelta(days=30 * i)).strftime("%Y-%m-%d")} for i in range(4)]
    assert constraints.check_5_24_status(history_safe) == True
    print("✅ 4 cards passed")
    
    # 3. Blocked User (5 cards in last 24 months)
    history_blocked = [{"date_opened": (now - timedelta(days=30 * i)).strftime("%Y-%m-%d")} for i in range(5)]
    assert constraints.check_5_24_status(history_blocked) == False
    print("✅ 5 cards blocked")
    
    # 4. Edge Case (5 cards, but 1 is old)
    history_mixed = [{"date_opened": (now - timedelta(days=30 * i)).strftime("%Y-%m-%d")} for i in range(4)]
    history_mixed.append({"date_opened": (now - timedelta(days=800)).strftime("%Y-%m-%d")}) # > 2 years
    assert constraints.check_5_24_status(history_mixed) == True
    print("✅ Old card ignored (Safe)")

def test_check_velocity():
    print("\nTesting check_velocity...")
    
    now = datetime.now()
    
    # 1. Safe (No last app)
    assert constraints.check_velocity(None) == True
    print("✅ No history passed")
    
    # 2. Safe (> 30 days)
    safe_date = (now - timedelta(days=32)).strftime("%Y-%m-%d")
    assert constraints.check_velocity(safe_date) == True
    print("✅ >30 days passed")
    
    # 3. Blocked (< 30 days)
    blocked_date = (now - timedelta(days=10)).strftime("%Y-%m-%d")
    assert constraints.check_velocity(blocked_date) == False
    print("✅ <30 days blocked")
    
    # 4. Exact Boundary (30 days) -> Should be Blocked logic says >= 30 days ago is FALSE?
    # Logic: if last_date >= thirty_days_ago: return False
    # So if exactly 30 days ago, it returns False (Blocked). valid?
    # Usually "wait 30 days". So on day 31 it's ok.
    # Logic seems consistent with "Reject if <30 days". 30 days exactly might be edge case but rejecting is safer.
    
if __name__ == "__main__":
    test_check_5_24_status()
    test_check_velocity()
    print("\n🎉 All Constraints Tests Passed!")
