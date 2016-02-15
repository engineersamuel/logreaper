module.exports = function(options) {
    // Babel6
    require('babel-register')({
        presets: ['es2015', 'stage-0']
    });
    require("./index")(options);
};
