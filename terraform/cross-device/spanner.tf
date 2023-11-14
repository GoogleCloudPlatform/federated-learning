# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Note: display_name max length = 30
resource "google_spanner_instance" "fcp_task_spanner_instance" {
  name             = "fcp-task-${var.environment}"
  display_name     = "fcp-task-${var.environment}"
  project          = var.project_id
  config           = var.spanner_instance_config
  processing_units = var.spanner_processing_units
}

resource "google_spanner_database" "fcp_task_spanner_database" {
  instance                 = google_spanner_instance.fcp_task_spanner_instance.name
  name                     = "fcp-task-db-${var.environment}"
  project                  = var.project_id
  version_retention_period = var.spanner_database_retention_period
  deletion_protection      = var.spanner_database_deletion_protection
  ddl = [
    "CREATE TABLE Task(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, TotalIteration INT64, MinAggregationSize INT64, MaxAggregationSize INT64, Status INT64, CreatedTime TIMESTAMP, StartTime TIMESTAMP, StopTime TIMESTAMP, StartTaskNoEarlierThan TIMESTAMP, DoNotCreateIterationAfter TIMESTAMP, MaxParallel INT64, CorrelationId STRING(MAX), MinClientVersion STRING(32), MaxClientVersion STRING(32)) PRIMARY KEY(PopulationName,TaskId)",
    "CREATE INDEX TaskMinCorrelationIdIndex ON Task(CorrelationId)",
    "CREATE INDEX TaskMinClientVersionIndex ON Task(MinClientVersion)",
    "CREATE INDEX TaskMaxClientVersionIndex ON Task(MaxClientVersion)",

    "CREATE TABLE TaskStatusHistory(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, StatusId INT64 NOT NULL, Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL) PRIMARY KEY(PopulationName, TaskId, StatusId), INTERLEAVE IN PARENT Task ON DELETE CASCADE",
    "CREATE INDEX TaskStatusHistoryStatusIndex ON TaskStatusHistory(Status)",
    "CREATE INDEX TaskStatusHistoryCreatedTimeIndex ON TaskStatusHistory(CreatedTime)",

    "CREATE TABLE Iteration (PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL, Status INT64 NOT NULL, BaseIterationId INT64 NOT NULL, BaseOnResultId INT64 NOT NULL, ReportGoal INT64 NOT NULL, ExpirationTime TIMESTAMP, ResultId INT64 NOT NULL) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId), INTERLEAVE IN PARENT Task ON DELETE CASCADE",
    "CREATE INDEX InterationStatusIndex on Iteration(Status)",
    "CREATE INDEX InterationExpirationTimeIndex on Iteration(ExpirationTime)",

    "CREATE TABLE IterationStatusHistory( PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL, StatusId INT64 NOT NULL, Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId, StatusId), INTERLEAVE IN PARENT Iteration ON DELETE CASCADE",
    "CREATE INDEX IterationStatusHistoryStatusIndex ON IterationStatusHistory(Status)",
    "CREATE INDEX IterationtStatusHistoryCreatedTimeIndex ON IterationStatusHistory(CreatedTime)",

    "CREATE TABLE Assignment(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL, SessionId STRING(64) NOT NULL, CorrelationId STRING(MAX), Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true)) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId, SessionId), INTERLEAVE IN PARENT Iteration ON DELETE CASCADE",
    "CREATE INDEX AssignmentCorrelationIdIndex ON Assignment(CorrelationId)",
    "CREATE INDEX AssignmentCreateTimeIndex ON Assignment(CreatedTime)",
    "CREATE INDEX AssignmentStatusIndex ON Assignment(Status)",

    "CREATE TABLE AssignmentStatusHistory(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL,SessionId STRING(64) NOT NULL, StatusId INT64 NOT NULL, Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId, SessionId, StatusId), INTERLEAVE IN PARENT Assignment ON DELETE CASCADE",
    "CREATE INDEX AssignmentStatusHistoryStatusIndex ON AssignmentStatusHistory(Status)",
    "CREATE INDEX AssignmentStatusHistoryCreatedTimeIndex ON AssignmentStatusHistory(CreatedTime)"
  ]
}
