const std = @import("std");
const c = @cImport({
    @cInclude("MagickWand/MagickWand.h");
});

pub fn main() !void {
    c.MagickWandGenesis();
    defer c.MagickWandTerminus();

    const wand = c.NewMagickWand();
    if (wand == null) {
        return error.MagickWandCreationFailed;
    }

    defer _ = c.DestroyMagickWand(wand);

    const status = c.MagickReadImage(wand, "input.png");
    if (status == c.MagickFalse) {
        var exeception_type: c.ExceptionType = undefined;
        const description = c.MagickGetException(wand, &exeception_type);
        defer _ = c.MagickRelinquishMemory(description);
        std.debug.print("Error reading image: {s}\n", .{description});
        return error.ImageReadFailed;
    }

    const sepai_status = c.MagickSepiaToneImage(wand, 58000);
    if (sepai_status == c.MagickFalse) {
        var exeception_type: c.ExceptionType = undefined;
        const description = c.MagickGetException(wand, &exeception_type);
        defer _ = c.MagickRelinquishMemory(description);
        std.debug.print("Error applying sepia filter: {s}\n", .{description});
        return error.SepaiToneFailed;
    }

    const write_status = c.MagickWriteImage(wand, "output.jpg");
    if (write_status == c.MagickFalse) {
        var exeception_type: c.ExceptionType = undefined;
        const description = c.MagickGetException(wand, &exeception_type);
        defer _ = c.MagickRelinquishMemory(description);
        std.debug.print("Error writing image: {s}\n", .{description});
        return error.ImageWriteFailed;
    }

    std.debug.print("Image processing completed successfully.", .{});
}
