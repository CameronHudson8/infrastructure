variable "kafka_version" {
  description = "The version of Kafka to use"
  type        = string
}

variable "storage_class_name" {
  description = "The storage class to use for the Kafka data volume"
  type        = string
}
