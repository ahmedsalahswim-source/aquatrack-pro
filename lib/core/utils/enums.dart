enum UserRole { parent, coach }

enum SubscriptionPlan { free, pro }

enum SwimLevel { beginner, intermediate, advanced, competitive }

enum Gender { male, female }

enum SleepQuality { poor, fair, good, excellent }

enum TrainingType { technique, endurance, sprint, dryland, competition, rest }

enum InjuryStatus { active, recovering, resolved }

enum InjurySeverity { mild, moderate, severe }

enum AlertType {
  highStress,
  highAcwr,
  lowSleep,
  highHeartRate,
  highRpe,
  weeklyReport,
  dailyReminder
}

enum AlertSeverity { info, warning, danger }

enum AiCategory { sleep, nutrition, training, recovery, injury, general }

enum AiTrigger { autoAlert, userQuery }

enum AiConfidence { high, medium, low }

enum UserFeedback { helpful, notHelpful }
