CREATE TABLE Task(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, TotalIteration INT64, MinAggregationSize INT64, MaxAggregationSize INT64, Status INT64, CreatedTime TIMESTAMP, StartTime TIMESTAMP, StopTime TIMESTAMP, StartTaskNoEarlierThan TIMESTAMP, DoNotCreateIterationAfter TIMESTAMP, MaxParallel INT64, CorrelationId STRING(MAX), MinClientVersion STRING(32), MaxClientVersion STRING(32)) PRIMARY KEY(PopulationName,TaskId)
CREATE INDEX TaskMinCorrelationIdIndex ON Task(CorrelationId)
CREATE INDEX TaskMinClientVersionIndex ON Task(MinClientVersion)
CREATE INDEX TaskMaxClientVersionIndex ON Task(MaxClientVersion)
CREATE TABLE TaskStatusHistory(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, StatusId INT64 NOT NULL, Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL) PRIMARY KEY(PopulationName, TaskId, StatusId), INTERLEAVE IN PARENT Task ON DELETE CASCADE
CREATE INDEX TaskStatusHistoryStatusIndex ON TaskStatusHistory(Status)
CREATE INDEX TaskStatusHistoryCreatedTimeIndex ON TaskStatusHistory(CreatedTime)
CREATE TABLE Iteration (PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL, Status INT64 NOT NULL, BaseIterationId INT64 NOT NULL, BaseOnResultId INT64 NOT NULL, ReportGoal INT64 NOT NULL, ExpirationTime TIMESTAMP, ResultId INT64 NOT NULL) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId), INTERLEAVE IN PARENT Task ON DELETE CASCADE
CREATE INDEX InterationStatusIndex on Iteration(Status)
CREATE INDEX InterationExpirationTimeIndex on Iteration(ExpirationTime)
CREATE TABLE IterationStatusHistory( PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL, StatusId INT64 NOT NULL, Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId, StatusId), INTERLEAVE IN PARENT Iteration ON DELETE CASCADE
CREATE INDEX IterationStatusHistoryStatusIndex ON IterationStatusHistory(Status)
CREATE INDEX IterationtStatusHistoryCreatedTimeIndex ON IterationStatusHistory(CreatedTime)
CREATE TABLE Assignment(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL, SessionId STRING(64) NOT NULL, CorrelationId STRING(MAX), Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true)) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId, SessionId), INTERLEAVE IN PARENT Iteration ON DELETE CASCADE
CREATE INDEX AssignmentCorrelationIdIndex ON Assignment(CorrelationId)
CREATE INDEX AssignmentCreateTimeIndex ON Assignment(CreatedTime)
CREATE INDEX AssignmentStatusIndex ON Assignment(Status)
CREATE TABLE AssignmentStatusHistory(PopulationName STRING(64) NOT NULL, TaskId INT64 NOT NULL, IterationId INT64 NOT NULL, AttemptId INT64 NOT NULL,SessionId STRING(64) NOT NULL, StatusId INT64 NOT NULL, Status INT64 NOT NULL, CreatedTime TIMESTAMP NOT NULL) PRIMARY KEY(PopulationName, TaskId, IterationId, AttemptId, SessionId, StatusId), INTERLEAVE IN PARENT Assignment ON DELETE CASCADE
CREATE INDEX AssignmentStatusHistoryStatusIndex ON AssignmentStatusHistory(Status)
CREATE INDEX AssignmentStatusHistoryCreatedTimeIndex ON AssignmentStatusHistory(CreatedTime)
