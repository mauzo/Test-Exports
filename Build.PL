use Module::Build;

Module::Build->new(
    module_name     => "Test::Exports",
    license         => "bsd",
    requires        => {
        "Test::Builder"     => 0,
        "B"                 => 0,
        "parent"            => 0,
    },
)->create_build_script;
