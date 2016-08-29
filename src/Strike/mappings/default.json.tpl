{
  "ni8": [
    [{
      "autoname": false,
      "id": 38,
      "name": "On/Off",
      "section": "EQ",
      "vflag": false
    }, {
      "autoname": false,
      "id": 41,
      "name": "Low",
      "vflag": false
    }, {
      "autoname": false,
      "id": 47,
      "name": "High",
      "vflag": false
    }, {
      "autoname": false,
      "id": 21,
      "name": "Close",
      "section": "Mics",
      "vflag": false
    }, {
      "autoname": false,
      "id": 24,
      "name": "Overhead",
      "vflag": false
    }, {
      "autoname": false,
      "id": 29,
      "name": "Room",
      "vflag": false
    }, {
      "autoname": false,
      "id": 36,
      "name": "Talkback",
      "vflag": false
    }, {
      "autoname": false,
      "id": 0,
      "name": "Level",
      "section": "Master",
      "vflag": false
    }],
    [{
      "autoname": false,
      "id": 55,
      "name": "On/Off",
      "section": "Dyn",
      "vflag": false
    }, {
      "autoname": false,
      "id": 56,
      "name": "Drive",
      "vflag": false
    }, {
      "autoname": false,
      "id": 59,
      "name": "Atack",
      "vflag": false
    }, {
      "autoname": false,
      "id": 18,
      "name": "Pitch",
      "section": "Tuning",
      "vflag": false
    }, {
      "autoname": false,
      "id": 14,
      "name": "Shift",
      "section": "Timber",
      "vflag": false
    }, {
      "autoname": false,
      "id": 7,
      "name": "Cent/Rim",
      "section": "Snare",
      "vflag": false
    }, {
      "autoname": false,
      "id": 8,
      "name": "Cls/Opn",
      "section": "HiHAT",
      "vflag": false
    }, {
      "autoname": false,
      "id": 136,
      "name": "Edge/Bel",
      "section": "Ride Cym",
      "vflag": false
    }],
    [{
      "autoname": false,
      "id": 138,
      "name": "Intensity",
      "section": "Smart Ctrl",
      "vflag": false
    }, {
      "autoname": false,
      "id": 3,
      "name": "Complex",
      "vflag": false
    }, {
      "autoname": true,
      "id": 9,
      "name": "Grid",
      "vflag": false
    }, {
      "autoname": true,
      "id": 2,
      "name": "Speed",
      "vflag": false
    }, {
      "autoname": false,
      "id": 135,
      "name": "Dynamics",
      "vflag": false
    }, {
      "autoname": false,
      "id": 15,
      "name": "Mode",
      "section": "Hit Var",
      "vflag": false
    }, {
      "autoname": false,
      "id": 13,
      "name": "Variance",
      "vflag": false
    }, {
      "autoname": true,
      "id": 10,
      "name": "Timing",
      "section": "Timing",
      "vflag": false
    }],
    [{
      "autoname": true,
      "id": 12,
      "name": "Feel",
      "section": "Feel",
      "vflag": false
    }, {
      "autoname": false,
      "id": 17,
      "name": "Template",
      "section": "Groove",
      "vflag": false
    }, {
      "autoname": false,
      "id": 11,
      "name": "Depth",
      "vflag": false
    }, {
      "autoname": false,
      "id": 6,
      "name": "On/Off",
      "section": "Jam",
      "vflag": false
    }, {
      "autoname": false,
      "id": 5,
      "name": "Density",
      "vflag": false
    }, {
      "autoname": true,
      "vflag": false
    }, {
      "autoname": true,
      "vflag": false
    }, {
      "autoname": true,
      "vflag": false
    }]
<% _.forEach(channels, function(channel) { %>
    ,
    [{
      "autoname": false,
      "id": <%= channel.index * 48 + 141 %>,
      "name": "Mute",
      "section": "<%= channel.name %>",
      "vflag": false
    }, {
      "autoname": false,
      "id": <%= channel.index * 48 + 142 %>,
      "name": "Solo",
      "vflag": false
    }, {
      "autoname": false,
      "id": <%= channel.index * 48 + 143 %>,
      "name": "Level",
      "vflag": false
    }, {
      "autoname": false,
      "id": <%= channel.index * 48 + 149 %>,
      "name": "Pan",
      "vflag": false
    }, {
      "autoname": false,
      "id": <%= channel.index * 48 + 162 %>,
      "name": "Tuning",
      "vflag": false
    }, {
      "autoname": false,
      "id": <%= channel.index * 48 + 158 %>,
      "name": "Timbre Shift",
      "vflag": false
    }, {
      "autoname": false,
      "id": <%= channel.index * 48 + 159 %>,
      "name": "Attack",
      "vflag": false
    }, {
      "autoname": false,
      "id": <%= channel.index * 48 + 160 %>,
      "name": "Decay",
      "vflag": false
    }]
<% }); %>
  ]
}
