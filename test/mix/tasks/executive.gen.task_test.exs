defmodule Mix.Tasks.Executive.Gen.TaskTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO, only: [with_io: 1]
  alias Executive.ParseError
  alias Mix.Tasks.Executive.Gen.Task, as: TaskGenerator

  defp expect_file(task_name, module, options, task_opts \\ "") do
    expected = """
    defmodule Mix.Tasks.#{module} do
      @shortdoc "TODO Describe this task in one line"
      @moduledoc \"""
      TODO Describe what this task does

          $ mix #{task_name}

      \"""
      use Executive.Task#{task_opts}

      moduledoc_append \"""
      ## Command line options

      \#{Executive.Schema.option_docs(&1)}

      \"""

      option_type option()
      options_type options()
    #{if byte_size(options) > 0, do: "\n" <> options, else: options}
      @impl Executive.Task
      def run(argv, opts) do
        # TODO implement this task
      end
    end
    """

    assert File.read!("lib/mix/tasks/#{task_name}.ex") == expected
  end

  defp generate(task_name, opts \\ []) do
    with_io(fn ->
      TaskGenerator.run([task_name | OptionParser.to_argv(opts)])
    end)
  end

  setup do
    tmp_dir = 24 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
    cwd = File.cwd!()

    on_exit(fn ->
      File.cd!(cwd)
      File.rm_rf!(tmp_dir)
    end)

    File.mkdir!(tmp_dir)
    File.cd!(tmp_dir)
  end

  describe "run/1" do
    test "creates task" do
      generate("something.do")
      expect_file("something.do", "Something.Do", "")
    end

    test "creates task with more complex name" do
      generate("something_else.do_quickly")
      expect_file("something_else.do_quickly", "SomethingElse.DoQuickly", "")
    end

    test "allows passing :start_application" do
      generate("something.do", start_application: true)
      expect_file("something.do", "Something.Do", "", ", start_application: true")
    end

    test "allows passing basic options" do
      generate("something.do", string: :my_string, integer: :my_integer)

      expect_file("something.do", "Something.Do", """
        option :my_string, :string
        option :my_integer, :integer
      """)
    end

    test "allows passing option aliases" do
      generate("something.do", uuid: :my_uuid, alias: :u, boolean: :my_boolean)

      expect_file("something.do", "Something.Do", """
        option :my_uuid, :uuid, alias: :u
        option :my_boolean, :boolean
      """)
    end

    test "allows passing docs" do
      generate("something.do", count: :my_count, doc: "counts things", integer: :my_integer)

      expect_file("something.do", "Something.Do", """
        @optdoc "counts things"
        option :my_count, :count
        option :my_integer, :integer
      """)
    end

    test "spaces out options with docs" do
      generate("something.do",
        integer: :my_integer,
        doc: "an integer",
        float: :my_float,
        doc: "a float"
      )

      expect_file("something.do", "Something.Do", """
        @optdoc "an integer"
        option :my_integer, :integer

        @optdoc "a float"
        option :my_float, :float
      """)
    end

    test "accepts boolean options" do
      generate("something.do", boolean: :my_boolean)

      expect_file("something.do", "Something.Do", """
        option :my_boolean, :boolean
      """)
    end

    test "accepts count options" do
      generate("something.do", count: :my_count)

      expect_file("something.do", "Something.Do", """
        option :my_count, :count
      """)
    end

    test "accepts float options" do
      generate("something.do", float: :my_float)

      expect_file("something.do", "Something.Do", """
        option :my_float, :float
      """)
    end

    test "accepts integer options" do
      generate("something.do", integer: :my_integer)

      expect_file("something.do", "Something.Do", """
        option :my_integer, :integer
      """)
    end

    test "accepts string options" do
      generate("something.do", string: :my_string)

      expect_file("something.do", "Something.Do", """
        option :my_string, :string
      """)
    end

    test "accepts uuid options" do
      generate("something.do", uuid: :my_uuid)

      expect_file("something.do", "Something.Do", """
        option :my_uuid, :uuid
      """)
    end

    test "allows passing required options" do
      generate("something.do", float: :my_float, required: true, boolean: :my_boolean)

      expect_file("something.do", "Something.Do", """
        option :my_float, :float, required: true
        option :my_boolean, :boolean
      """)
    end

    test "allows passing option uniqueness" do
      generate("something.do", string: :my_string, unique: false, string: :another_string)

      expect_file("something.do", "Something.Do", """
        option :my_string, :string, unique: false
        option :another_string, :string
      """)
    end

    test "fails if switch name and type are mixed up" do
      message = "1 error found!\n--my-integer : Unknown option"

      assert_raise ParseError, message, fn ->
        generate("something.do", my_integer: :integer)
      end
    end

    test "fails if no task name given" do
      argv = OptionParser.to_argv(string: :my_string, required: true)
      message = "Expected exactly 1 non-switch argument, got 0"

      assert_raise RuntimeError, message, fn ->
        TaskGenerator.run(argv)
      end
    end

    test "fails if too many task names given" do
      argv = ["something.do", "something_else.do"]
      message = "Expected exactly 1 non-switch argument, got 2"

      assert_raise RuntimeError, message, fn ->
        TaskGenerator.run(argv)
      end
    end

    test "fails if :alias given before type" do
      message = "Modifier switch --alias must follow a type switch"

      assert_raise RuntimeError, message, fn ->
        generate("something.do", alias: :b, boolean: :my_boolean)
      end
    end

    test "fails if :doc given before type" do
      message = "Modifier switch --doc must follow a type switch"

      assert_raise RuntimeError, message, fn ->
        generate("something.do", doc: "my count", count: :my_count)
      end
    end

    test "fails if :required given before type" do
      message = "Modifier switch --required must follow a type switch"

      assert_raise RuntimeError, message, fn ->
        generate("something.do", required: true, float: :my_float)
      end
    end
  end
end
