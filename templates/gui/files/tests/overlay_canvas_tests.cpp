#include <@@NS_PATH@@/types.hpp>
#include <catch2/catch_test_macros.hpp>

TEST_CASE("OverlayCanvas pushes and stores commands", "[overlay_canvas]") {
    @@NS@@::OverlayCanvas canvas;

    REQUIRE(canvas.commands().empty());

    // Push various draw commands
    @@NS@@::DrawCommand line_cmd;
    line_cmd.type = @@NS@@::DrawType::Line;
    line_cmd.x1 = 10.0f;
    line_cmd.y1 = 20.0f;
    line_cmd.x2 = 100.0f;
    line_cmd.y2 = 200.0f;
    line_cmd.color = 0xFF00FF00;
    canvas.push_command(line_cmd);

    @@NS@@::DrawCommand rect_cmd;
    rect_cmd.type = @@NS@@::DrawType::Rect;
    rect_cmd.x1 = 50.0f;
    rect_cmd.y1 = 50.0f;
    rect_cmd.x2 = 150.0f;
    rect_cmd.y2 = 150.0f;
    rect_cmd.color = 0xFF0000FF;
    canvas.push_command(rect_cmd);

    const auto& commands = canvas.commands();
    REQUIRE(commands.size() == 2);

    CHECK(commands[0].type == @@NS@@::DrawType::Line);
    CHECK(commands[1].type == @@NS@@::DrawType::Rect);
}

TEST_CASE("OverlayCanvas clear removes all commands", "[overlay_canvas]") {
    @@NS@@::OverlayCanvas canvas;

    @@NS@@::DrawCommand cmd;
    cmd.x1 = 0.0f;
    cmd.y1 = 0.0f;
    cmd.x2 = 10.0f;
    cmd.y2 = 10.0f;
    canvas.push_command(cmd);
    canvas.push_command(cmd);

    REQUIRE(canvas.commands().size() == 2);

    canvas.clear();

    REQUIRE(canvas.commands().empty());
}

TEST_CASE("OverlayCanvas validates DrawCommand fields", "[overlay_canvas]") {
    @@NS@@::DrawCommand cmd_line;
    cmd_line.type = @@NS@@::DrawType::Line;
    cmd_line.x1 = 10.0f;
    cmd_line.y1 = 20.0f;
    cmd_line.x2 = 30.0f;
    cmd_line.y2 = 40.0f;
    cmd_line.color = 0xFF00FF00;

    CHECK(cmd_line.x1 == 10.0f);
    CHECK(cmd_line.y1 == 20.0f);
    CHECK(cmd_line.x2 == 30.0f);
    CHECK(cmd_line.y2 == 40.0f);
    CHECK(cmd_line.color == 0xFF00FF00);
}
