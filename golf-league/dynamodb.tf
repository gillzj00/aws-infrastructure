# ──────────────────────────────────────────────
# DynamoDB Tables
# ──────────────────────────────────────────────

resource "aws_dynamodb_table" "leagues" {
  name         = "${var.project_name}-leagues"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "slug"
    type = "S"
  }

  global_secondary_index {
    name            = "slug-index"
    hash_key        = "slug"
    projection_type = "ALL"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-leagues"
      Environment = var.environment
    }
  )
}

resource "aws_dynamodb_table" "players" {
  name         = "${var.project_name}-players"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "league_id"
    type = "S"
  }

  attribute {
    name = "auth_token_hash"
    type = "S"
  }

  global_secondary_index {
    name            = "league-index"
    hash_key        = "league_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "token-index"
    hash_key        = "auth_token_hash"
    projection_type = "ALL"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-players"
      Environment = var.environment
    }
  )
}

resource "aws_dynamodb_table" "rounds" {
  name         = "${var.project_name}-rounds"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "league_id"
    type = "S"
  }

  global_secondary_index {
    name            = "league-index"
    hash_key        = "league_id"
    projection_type = "ALL"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-rounds"
      Environment = var.environment
    }
  )
}

resource "aws_dynamodb_table" "scores" {
  name         = "${var.project_name}-scores"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "round_id"
    type = "S"
  }

  attribute {
    name = "player_id"
    type = "S"
  }

  global_secondary_index {
    name            = "round-index"
    hash_key        = "round_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "player-index"
    hash_key        = "player_id"
    projection_type = "ALL"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-scores"
      Environment = var.environment
    }
  )
}
