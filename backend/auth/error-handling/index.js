module.exports = (app) => {
  app.use((req, res, next) => {
    // this middleware runs whenever requested page is not available
    res.status(404).json({ message: "This route does not exist" });
  });

  app.use((err, req, res, next) => {
  console.error("ERROR", req.method, req.path, err);

  if (err.name === "UnauthorizedError" && !res.headersSent) {
    return res.status(401).json({
      message: "Invalid or missing token"
    });
  }

  if (!res.headersSent) {
    res.status(500).json({
      message: "Internal server error. Check the server console",
    });
  }
});
};
