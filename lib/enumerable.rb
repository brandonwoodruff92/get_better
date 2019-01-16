module Enumerable
  
  def get(params = {})
    find do |record|
      params.all? do |column_and_operator, value|
        get_by_column_and_operator(record.is_a?(Hash) ? record.to_struct : record, column_and_operator, value)
      end
    end
  end

  def get_all(params = {})
    find_all do |record|
      params.all? do |column_and_operator, value|
        get_by_column_and_operator(record.is_a?(Hash) ? record.to_struct : record, column_and_operator, value)
      end
    end
  end

  def get_or(params = {})
    find do |record|
      params.any? do |column_and_operator, value|
        get_by_column_and_operator(record.is_a?(Hash) ? record.to_struct : record, column_and_operator, value)
      end
    end
  end

  def get_all_or(params = {})
    find_all do |record|
      params.any? do |column_and_operator, value|
        get_by_column_and_operator(record.is_a?(Hash) ? record.to_struct : record, column_and_operator, value)
      end
    end
  end

  def get_by_column_and_operator(record, column_and_operator, value)
    column, operator = split_column_and_operator(column_and_operator.to_s)
    column_value = column.nil? ? record : record.send(column)
    case operator
    when "eq"      then column_value == value
    when "not_eq"  then column_value != value
    when "lt"      then column_value < value
    when "gt"      then column_value > value
    when "lteq"    then column_value <= value
    when "gteq"    then column_value >= value
    when "ieq"     then column_value.to_s.downcase == value.to_s.downcase
    when "not_ieq" then column_value.to_s.downcase != value.to_s.downcase
    when "in", "not_in"
      if value.is_a?(Array)
        is_in = column_value.in?(value)
        operator == "in" ? is_in : !is_in
      else
        raise(ArgumentError, "get with an '##{operator}' operator expects an array")
      end
    when "matches", "does_not_match"
      does_match =
        if value.is_a?(String)
          value.include?(column_value)
        elsif value.is_a?(Regexp)
          column_value =~ value
        else
          raise(ArgumentError, "get with an '#{operator}' operator expects a string or regex")
        end
      operator == "matches" ? does_match : !does_match
    else
      raise(ArgumentError, "Unknown operator")
    end
  end

  def split_column_and_operator(column_and_operator)
    operators = {
      does_not_match: /_does_not_match\z/,
      matches: /_matches\z/,
      not_in: /_not_in\z/,
      not_ieq: /_not_ieq\z/,
      not_eq: /_not_eq\z/,
      lteq: /_lteq\z/,
      gteq: /_gteq\z/,
      in: /_in\z/,
      ieq: /_ieq\z/,
      eq: /_eq\z/,
      lt: /_lt\z/,
      gt: /_gt\z/,
    }.with_indifferent_access
    # If column_and_operator is one of the operators (i.e not_eq). Prevents not from getting assigned as column.
    if column_and_operator.in?(operators.keys)
      [nil, column_and_operator]
    else
      operator, operator_regex = operators.find { |operator, regex| column_and_operator =~ regex }
      if !operator || !operator_regex
        [column_and_operator, "eq"]
      else
        [column_and_operator.remove(operator_regex), operator]
      end
    end
  end
end
