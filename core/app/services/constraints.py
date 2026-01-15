from datetime import datetime, timedelta

def check_5_24_status(opened_cards_history: list[dict]) -> bool:
    """
    Checks if the user is under the 5/24 rule.
    Returns True if user is SAFE (<= 4 cards in last 24 months).
    Returns False if user is BLOCKED (>= 5 cards).
    
    Expected format for opened_cards_history:
    [
        {"date_opened": "2024-01-15", "issuer": "Chase", ...},
        ...
    ]
    """
    if not opened_cards_history:
        return True
        
    twenty_four_months_ago = datetime.now() - timedelta(days=365 * 2)
    
    count = 0
    for card in opened_cards_history:
        # Assuming date string is ISO or similar. Need to handle parsing robustly.
        # Let's assume input is cleaned or datetimes, but usually input is string from DB.
        date_str = card.get("date_opened")
        if not date_str:
            continue
            
        try:
             # Try parsing ISO format YYYY-MM-DD
            opened_date = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            try:
                # Try with time if present
                opened_date = datetime.fromisoformat(date_str)
                # Remove timezone for comparison if simple naive check is okay, 
                # or ensure twenty_four_months_ago is offset-aware. 
                # For simplicity in this logic, we'll aim for naive comparison for now unless stricter needed.
                if opened_date.tzinfo:
                     opened_date = opened_date.replace(tzinfo=None)
            except Exception:
                continue

        if opened_date >= twenty_four_months_ago:
            count += 1
            
    return count < 5

def check_velocity(last_application_date: str | None) -> bool:
    """
    Checks if enough time has passed since the last application.
    Returns True if user is SAFE (> 30 days since last app).
    Returns False if user is BLOCKED (<= 30 days).
    """
    if not last_application_date:
        return True
        
    try:
        last_date = datetime.strptime(last_application_date, "%Y-%m-%d")
    except ValueError:
        try:
             last_date = datetime.fromisoformat(last_application_date)
             if last_date.tzinfo:
                 last_date = last_date.replace(tzinfo=None)
        except Exception:
            # If date is invalid, we can't block, or we should default to safe/block?
            # Defaulting to Safe to avoid permanent blocking on bad data.
            return True

    thirty_days_ago = datetime.now() - timedelta(days=30)
    
    if last_date >= thirty_days_ago:
        return False
        
    return True
