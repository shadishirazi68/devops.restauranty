const express = require('express');
const router = express.Router();
const { isAuthenticated } = require('../middleware/jwt.middleware');

// Security fix: these routes were public (list, read, update and delete users).
// They now require a valid JWT, and the password hash is never returned.
router.use(isAuthenticated);

const User = require('../models/User.model')

// const fileUploader = require('./../config/cloudinary.config')

router.get("/", (req, res) => {

    User.find().select("-password").then(users => {
        res.json(users)
    }).catch(err => {
        res.status(400).json(err)
    })

})

router.get("/:id", (req, res) => {

    const id = req.params.id

    User.findById(id).select("-password").then(user => {
        res.json(user)
    }).catch(err => {
        res.status(400).json(err)
    })

})

router.put("/", (req, res) => {

    const user = req.body

    user.findByIdAndUpdate(user._id, user, { new: true }).then(newUser => {
        res.json(newUser)
    }).catch(err => {
        res.status(400).json(err)
    })

})

router.delete("/:id", (req, res) => {

    const id = req.params.id

    User.findByIdAndDelete(id).then(userDeleted => {
        res.json({
            message: "User Eliminado",
            userDeleted
        })
    }).catch(err => {
        res.status(400).json(err)
    })

})

module.exports = router;
