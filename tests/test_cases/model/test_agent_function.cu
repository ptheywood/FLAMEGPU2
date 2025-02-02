#include "flamegpu/flamegpu.h"

#include "gtest/gtest.h"

namespace flamegpu {


namespace test_agent_function {
FLAMEGPU_AGENT_FUNCTION(agent_fn1, MessageBruteForce, MessageBruteForce) {
    // do nothing
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(agent_fn2, MessageNone, MessageNone) {
    // do nothing
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(agent_fn3, MessageNone, MessageNone) {
    // do nothing
    return ALIVE;
}

const char *MODEL_NAME = "Model";
const char *WRONG_MODEL_NAME = "Model2";
const char *AGENT_NAME = "Agent1";
const char *AGENT_NAME2 = "Agent2";
const char *AGENT_NAME3 = "Agent3";
const char *MESSAGE_NAME1 = "Message1";
const char *MESSAGE_NAME2 = "Message2";
const char *VARIABLE_NAME1 = "Var1";
const char *VARIABLE_NAME2 = "Var2";
const char *VARIABLE_NAME3 = "Var3";
const char *FUNCTION_NAME1 = "Function1";
const char *FUNCTION_NAME2 = "Function2";
const char *FUNCTION_NAME3 = "Function3";
const char *STATE_NAME = "State1";
const char *NEW_STATE_NAME = "State2";
const char *WRONG_STATE_NAME = "State3";
const char *OTHER_STATE_NAME = "State4";

TEST(AgentFunctionDescriptionTest, InitialState) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    AgentDescription &a2 = _m.newAgent(AGENT_NAME2);
    AgentDescription &a3 = _m.newAgent(AGENT_NAME3);
    a2.newState(STATE_NAME);
    a3.newState(ModelData::DEFAULT_STATE);
    a2.newState(NEW_STATE_NAME);
    a3.newState(NEW_STATE_NAME);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    AgentFunctionDescription &f2 = a2.newFunction(FUNCTION_NAME2, agent_fn2);
    AgentFunctionDescription &f3 = a3.newFunction(FUNCTION_NAME3, agent_fn3);
    // Initial state begins whatever agent's initial state is
    EXPECT_EQ(f.getInitialState(), a.getInitialState());
    EXPECT_EQ(f2.getInitialState(), a2.getInitialState());
    EXPECT_EQ(f3.getInitialState(), a3.getInitialState());
    // Can change the initial state
    // f.setInitialState(NEW_STATE_NAME); // Don't perform this here, would need to change from default state
    f2.setInitialState(NEW_STATE_NAME);
    f3.setInitialState(NEW_STATE_NAME);
    // Returned value is same
    // EXPECT_EQ(f.getInitialState(), NEW_STATE_NAME);
    EXPECT_EQ(f2.getInitialState(), NEW_STATE_NAME);
    EXPECT_EQ(f3.getInitialState(), NEW_STATE_NAME);
    // Replacing agent's default state will replace their initial state
    a.newState(NEW_STATE_NAME);
    EXPECT_EQ(f.getInitialState(), NEW_STATE_NAME);
    // Can't set state to one not held by parent agent
    EXPECT_THROW(f.setInitialState(WRONG_STATE_NAME), exception::InvalidStateName);
    EXPECT_THROW(f2.setInitialState(WRONG_STATE_NAME), exception::InvalidStateName);
    EXPECT_THROW(f3.setInitialState(WRONG_STATE_NAME), exception::InvalidStateName);
}
TEST(AgentFunctionDescriptionTest, EndState) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    AgentDescription &a2 = _m.newAgent(AGENT_NAME2);
    AgentDescription &a3 = _m.newAgent(AGENT_NAME3);
    a2.newState(STATE_NAME);
    a3.newState(ModelData::DEFAULT_STATE);
    a2.newState(NEW_STATE_NAME);
    a3.newState(NEW_STATE_NAME);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    AgentFunctionDescription &f2 = a2.newFunction(FUNCTION_NAME2, agent_fn2);
    AgentFunctionDescription &f3 = a3.newFunction(FUNCTION_NAME3, agent_fn3);
    // End state begins whatever agent's end state is
    EXPECT_EQ(f.getEndState(), a.getInitialState());
    EXPECT_EQ(f2.getEndState(), a2.getInitialState());
    EXPECT_EQ(f3.getEndState(), a3.getInitialState());
    // Can change the end state
    // f.setEndState(NEW_STATE_NAME); // Don't perform this here, would need to change from default state
    f2.setEndState(NEW_STATE_NAME);
    f3.setEndState(NEW_STATE_NAME);
    // Returned value is same
    // EXPECT_EQ(f.getEndState(), NEW_STATE_NAME);
    EXPECT_EQ(f2.getEndState(), NEW_STATE_NAME);
    EXPECT_EQ(f3.getEndState(), NEW_STATE_NAME);
    // Replacing agent's default state will replace their end state
    a.newState(NEW_STATE_NAME);
    EXPECT_EQ(f.getEndState(), NEW_STATE_NAME);
    // Can't set state to one not held by parent agent
    EXPECT_THROW(f.setEndState(WRONG_STATE_NAME), exception::InvalidStateName);
    EXPECT_THROW(f2.setEndState(WRONG_STATE_NAME), exception::InvalidStateName);
    EXPECT_THROW(f3.setEndState(WRONG_STATE_NAME), exception::InvalidStateName);
}
TEST(AgentFunctionDescriptionTest, MessageInput) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    MessageBruteForce::Description &m = _m.newMessage(MESSAGE_NAME1);
    MessageBruteForce::Description &m2 = _m.newMessage(MESSAGE_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Begins empty
    EXPECT_FALSE(f.hasMessageInput());
    EXPECT_THROW(f.getMessageInput(), exception::OutOfBoundsException);
    // Can be set
    f.setMessageInput(m);
    EXPECT_TRUE(f.hasMessageInput());
    // Returns the expected value
    EXPECT_EQ(f.getMessageInput(), m);
    // Can be updated
    f.setMessageInput(m2);
    EXPECT_TRUE(f.hasMessageInput());
    // Returns the expected value
    EXPECT_EQ(f.getMessageInput(), m2);
}
TEST(AgentFunctionDescriptionTest, MessageOutput) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    MessageBruteForce::Description &m = _m.newMessage(MESSAGE_NAME1);
    MessageBruteForce::Description &m2 = _m.newMessage(MESSAGE_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Begins empty
    EXPECT_FALSE(f.hasMessageOutput());
    EXPECT_THROW(f.getMessageOutput(), exception::OutOfBoundsException);
    // Can be set
    f.setMessageOutput(m);
    EXPECT_TRUE(f.hasMessageOutput());
    // Returns the expected value
    EXPECT_EQ(f.getMessageOutput(), m);
    // Can be updated
    f.setMessageOutput(m2);
    EXPECT_TRUE(f.hasMessageOutput());
    // Returns the expected value
    EXPECT_EQ(f.getMessageOutput(), m2);
}
TEST(AgentFunctionDescriptionTest, MessageOutputOptional) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Begins disabled
    EXPECT_FALSE(f.getMessageOutputOptional());
    EXPECT_FALSE(f.MessageOutputOptional());
    // Can be updated
    f.MessageOutputOptional() = true;
    EXPECT_TRUE(f.getMessageOutputOptional());
    EXPECT_TRUE(f.MessageOutputOptional());
    f.setMessageOutputOptional(false);
    EXPECT_FALSE(f.getMessageOutputOptional());
    EXPECT_FALSE(f.MessageOutputOptional());
}
TEST(AgentFunctionDescriptionTest, AgentOutput) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    AgentDescription &a2 = _m.newAgent(AGENT_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Begins empty
    EXPECT_FALSE(f.hasAgentOutput());
    EXPECT_THROW(f.getAgentOutput(), exception::OutOfBoundsException);
    // Can be set
    f.setAgentOutput(a);
    EXPECT_TRUE(f.hasAgentOutput());
    // Returns the expected value
    EXPECT_EQ(f.getAgentOutput(), a);
    // Can be updated
    f.setAgentOutput(a2);
    EXPECT_TRUE(f.hasAgentOutput());
    // Returns the expected value
    EXPECT_EQ(f.getAgentOutput(), a2);
}
TEST(AgentFunctionDescriptionTest, AgentOutputState) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    AgentDescription &a2 = _m.newAgent(AGENT_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Can't set it to a state that doesn't exist
    EXPECT_THROW(f.setAgentOutput(a, "wrong"), exception::InvalidStateName);
    a.newState("a");
    a.newState("b");
    a2.newState("c");
    EXPECT_THROW(f.setAgentOutput(a, "c"), exception::InvalidStateName);
    // Can set it to a valid state though
    EXPECT_NO_THROW(f.setAgentOutput(a, "a"));
    // Can't set it to default if default not a state
    EXPECT_THROW(f.setAgentOutput(a), exception::InvalidStateName);
    // Returns the expected value
    EXPECT_EQ(f.getAgentOutputState(), "a");
    // Can be updated
    f.setAgentOutput(a, "b");
    EXPECT_TRUE(f.hasAgentOutput());
    // Returns the expected value
    EXPECT_EQ(f.getAgentOutputState(), "b");
    // Can be updated different agent
    f.setAgentOutput(a2, "c");
    // Returns the expected value
    EXPECT_EQ(f.getAgentOutputState(), "c");
}
TEST(AgentFunctionDescriptionTest, AllowAgentDeath) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Begins disabled
    EXPECT_FALSE(f.getAllowAgentDeath());
    EXPECT_FALSE(f.AllowAgentDeath());
    // Can be updated
    f.AllowAgentDeath() = true;
    EXPECT_TRUE(f.getAllowAgentDeath());
    EXPECT_TRUE(f.AllowAgentDeath());
    f.setAllowAgentDeath(false);
    EXPECT_FALSE(f.getAllowAgentDeath());
    EXPECT_FALSE(f.AllowAgentDeath());
}

TEST(AgentFunctionDescriptionTest, MessageInput_WrongModel) {
    ModelDescription _m(MODEL_NAME);
    ModelDescription _m2(WRONG_MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    MessageBruteForce::Description &m1 = _m.newMessage(MESSAGE_NAME1);
    MessageBruteForce::Description &m2 = _m2.newMessage(MESSAGE_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);

    EXPECT_THROW(f.setMessageInput(m2), exception::DifferentModel);
    EXPECT_NO_THROW(f.setMessageInput(m1));
}
TEST(AgentFunctionDescriptionTest, MessageOutput_WrongModel) {
    ModelDescription _m(MODEL_NAME);
    ModelDescription _m2(WRONG_MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    MessageBruteForce::Description &m1 = _m.newMessage(MESSAGE_NAME1);
    MessageBruteForce::Description &m2 = _m2.newMessage(MESSAGE_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);

    EXPECT_THROW(f.setMessageOutput(m2), exception::DifferentModel);
    EXPECT_NO_THROW(f.setMessageOutput(m1));
}
TEST(AgentFunctionDescriptionTest, AgentOutput_WrongModel) {
    ModelDescription _m(MODEL_NAME);
    ModelDescription _m2(WRONG_MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    AgentDescription &a2 = _m2.newAgent(AGENT_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);

    EXPECT_THROW(f.setAgentOutput(a2), exception::DifferentModel);
    EXPECT_NO_THROW(f.setAgentOutput(a));
}
TEST(AgentFunctionDescriptionTest, MessageInputOutput) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    MessageBruteForce::Description &m = _m.newMessage(MESSAGE_NAME1);
    MessageBruteForce::Description &m2 = _m.newMessage(MESSAGE_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Cannot bind same message to input and output
    EXPECT_NO_THROW(f.setMessageInput(m));
    EXPECT_THROW(f.setMessageOutput(m), exception::InvalidMessageName);
    EXPECT_NO_THROW(f.setMessageOutput(m2));
}
TEST(AgentFunctionDescriptionTest, MessageOutputInput) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    MessageBruteForce::Description &m = _m.newMessage(MESSAGE_NAME1);
    MessageBruteForce::Description &m2 = _m.newMessage(MESSAGE_NAME2);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn1);
    // Cannot bind same message to output and input
    EXPECT_NO_THROW(f.setMessageOutput(m));
    EXPECT_THROW(f.setMessageInput(m), exception::InvalidMessageName);
    EXPECT_NO_THROW(f.setMessageInput(m2));
}
TEST(AgentFunctionDescriptionTest, SameAgentAndStateInLayer) {
    ModelDescription _m(MODEL_NAME);
    AgentDescription &a = _m.newAgent(AGENT_NAME);
    a.newState(STATE_NAME);
    a.newState(NEW_STATE_NAME);
    a.newState(WRONG_STATE_NAME);
    a.newState(OTHER_STATE_NAME);
    AgentFunctionDescription &f = a.newFunction(FUNCTION_NAME1, agent_fn2);
    f.setInitialState(STATE_NAME);
    f.setEndState(NEW_STATE_NAME);
    AgentFunctionDescription &f2 = a.newFunction(FUNCTION_NAME2, agent_fn3);
    f2.setInitialState(WRONG_STATE_NAME);
    f2.setEndState(OTHER_STATE_NAME);
    LayerDescription &l = _m.newLayer();
    // start matches end state
    EXPECT_NO_THROW(l.addAgentFunction(agent_fn2));
    EXPECT_NO_THROW(l.addAgentFunction(agent_fn3));
    EXPECT_THROW(f2.setInitialState(STATE_NAME), exception::InvalidAgentFunc);
    EXPECT_THROW(f2.setInitialState(NEW_STATE_NAME), exception::InvalidAgentFunc);
    EXPECT_THROW(f2.setEndState(STATE_NAME), exception::InvalidAgentFunc);
    EXPECT_THROW(f2.setEndState(NEW_STATE_NAME), exception::InvalidAgentFunc);
}

}  // namespace test_agent_function
}  // namespace flamegpu
