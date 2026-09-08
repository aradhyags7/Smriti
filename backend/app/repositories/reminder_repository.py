# SMRITI - Reminder Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.reminder import Reminder

class ReminderRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_reminder(self, reminder: Reminder) -> Reminder:
        merged = self.db.merge(reminder)
        self.db.commit()
        return merged

    def get_patient_reminders(self, patient_id: str) -> List[Reminder]:
        return (
            self.db.query(Reminder)
            .filter(Reminder.patient_id == patient_id)
            .order_by(Reminder.scheduled_time.asc())
            .all()
        )

    def acknowledge_reminder(self, reminder_id: str) -> Optional[Reminder]:
        reminder = self.db.query(Reminder).filter(Reminder.id == reminder_id).first()
        if reminder:
            reminder.is_acknowledged = True
            self.db.commit()
            self.db.refresh(reminder)
        return reminder
