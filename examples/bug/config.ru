class HelloWorld
  JSON_TYPE = "application/json".freeze
  PLAINTEXT_TYPE = "text/plain".freeze
  
  def respond(type, body)
    [200, { "Content-Type" => type }, [body]]
  end
  
  def call(env)
    case env["PATH_INFO"]
    when "/json"
      # Test type 1: JSON serialization
      return respond JSON_TYPE,
              Oj.dump({ message: "Hello, World!" }, { mode: :strict })
    when "/plaintext"
      # Test type 6: Plaintext
      return respond PLAINTEXT_TYPE, "Hello, World!"
    end

    [200, {}, []]
  end
end

# run HelloWorld.new

run do
end
