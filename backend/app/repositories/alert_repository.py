# SMRITI - Alert Repository
# Owner: Aradhya (AI + Database + Sync)

from typing import List, Optional
from sqlalchemy.orm import Session
from backend.app.models.alert import Alert

class AlertRepository:
    def __init__(self, db: Session):
        self.db = db

    def save_alert(self, alert: Alert) -> Alert:
        self.db.add(alert)
        self.db.commit()
        self.db.refresh(alert)
        return alert

    def get_alerts(self, patient_id: Optional[str] = None, for_asha: bool = False) -> List[Alert]:
        query = self.db.query(Alert)
        if patient_id:
            query = query.filter(Alert.patient_id == patient_id)
        if for_asha:
            # Privacy & consent gate: only alerts where patient consented to rural worker sharing
            query = query.filter(
                Alert.patient_consent_given == True,
                Alert.asha_notified == True
            )
        return query.order_by(Alert.created_at.desc()).all()

    def get_unacknowledged_alerts(self, patient_id: Optional[str] = None) -> List[Alert]:
        query = self.db.query(Alert).filter(Alert.is_acknowledged == False)
        if patient_id:
            query = query.filter(Alert.patient_id == patient_id)
        return query.order_by(Alert.created_at.desc()).all()

    def acknowledge_alert(self, alert_id: str) -> Optional[Alert]:
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
        if alert:
            alert.is_acknowledged = True
            self.db.commit()
            self.db.refresh(alert)
        return alert
