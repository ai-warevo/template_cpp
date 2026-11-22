#include <@@NS_PATH@@/types.hpp>
#include <catch2/catch_test_macros.hpp>

TEST_CASE("OverlayCanvas pushes and stores commands", "[overlay_canvas]") {
    @@NS@@::OverlayCanvas canvas;

    REQUIRE(canvas.commands().empty());

    canvas.push_line(10.0f, 20.0f, 100.0f, 200.0f, 0xFF00FF00);
    canvas.push_rect(50.0f, 50.0f, 150.0f, 150.0f, 0xFF0000FF);
    canvas.push_circle(200.0f, 200.0f, 30.0f, 0xFFFF0000);
    canvas.push_text(300.0f, 300.0f, "Test", 0xFFFFFFFF);

    const auto& commands = canvas.commands();
    REQUIRE(commands.size() == 4);

    CHECK(commands[0].type == @@NS@@::DrawType::Line);
    CHECK(commands[1].type == @@NS@@::DrawType::Rect);
    CHECK(commands[2].type == @@NS@@::DrawType::Circle);
    CHECK(commands[3].type == @@NS@@::DrawType::Text);
}

TEST_CASE("OverlayCanvas clear removes all commands", "[overlay_canvas]") {
    @@NS@@::OverlayCanvas canvas;

    canvas.push_line(0.0f, 0.0f, 10.0f, 10.0f, 0xFF000000);
    canvas.push_rect(0.0f, 0.0f, 10.0f, 10.0f, 0xFF000000);

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

TEST_CASE("OverlayCanvas text command stores string correctly", "[overlay_canvas]") {
    @@NS@@::OverlayCanvas canvas;

    const std::string test_text = "Hello, World!";
    canvas.push_text(100.0f, 200.0f, test_text, 0xFFFFFFFF);

    const auto& commands = canvas.commands();
    REQUIRE(commands.size() == 1);
    REQUIRE(commands[0].type == @@NS@@::DrawType::Text);
    CHECK(commands[0].text == test_text);
}
