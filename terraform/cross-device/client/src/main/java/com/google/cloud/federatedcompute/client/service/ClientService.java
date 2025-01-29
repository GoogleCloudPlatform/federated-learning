/*
 * Copyright 2023 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.cloud.federatedcompute.client.service;

import com.google.cloud.federatedcompute.client.config.ClientConfig;
import com.google.cloud.federatedcompute.client.model.Task;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.RestClientException;

@Service
public class ClientService {
    private static final Logger logger = LoggerFactory.getLogger(ClientService.class);
    
    private final RestTemplate restTemplate;
    private final ClientConfig config;
    private final TaskProcessor taskProcessor;
    
    public ClientService(RestTemplate restTemplate, ClientConfig config, TaskProcessor taskProcessor) {
        this.restTemplate = restTemplate;
        this.config = config;
        this.taskProcessor = taskProcessor;
    }
    
    @Scheduled(fixedDelayString = "${odp.client.polling-interval:60000}")
    public void checkForTasks() {
        try {
            Task task = fetchTask();
            if (task != null) {
                processTask(task);
            }
        } catch (Exception e) {
            logger.error("Error checking for tasks", e);
        }
    }
    
    @Retryable(
        value = { RestClientException.class },
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2)
    )
    private Task fetchTask() {
        String url = config.getServiceUrl() + "/tasks/assign?clientId=" + config.getClientId();
        ResponseEntity<Task> response = restTemplate.getForEntity(url, Task.class);
        
        if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
            logger.info("Received task: {}", response.getBody().getTaskId());
            return response.getBody();
        }
        return null;
    }
    
    private void processTask(Task task) {
        try {
            byte[] result = taskProcessor.processTask(task);
            submitResults(task.getTaskId(), result);
        } catch (Exception e) {
            logger.error("Error processing task: {}", task.getTaskId(), e);
            reportTaskFailure(task.getTaskId(), e.getMessage());
        }
    }
    
    @Retryable(
        value = { RestClientException.class },
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2)
    )
    private void submitResults(String taskId, byte[] results) {
        String url = config.getServiceUrl() + "/tasks/" + taskId + "/results";
        restTemplate.postForEntity(url, results, Void.class);
        logger.info("Submitted results for task: {}", taskId);
    }
    
    private void reportTaskFailure(String taskId, String error) {
        String url = config.getServiceUrl() + "/tasks/" + taskId + "/failure";
        restTemplate.postForEntity(url, error, Void.class);
        logger.info("Reported failure for task: {}", taskId);
    }
}
